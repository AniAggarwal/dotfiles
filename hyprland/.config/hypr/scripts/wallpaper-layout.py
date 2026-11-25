#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["numpy", "pillow"]
# ///
"""Pick where the desktop clock sits on a wallpaper, once per wallpaper.

    wallpaper-layout.py WALLPAPER OUT.json --screen eDP-1:2304x1440 --screen DP-2:5120x2160

For each screen the wallpaper is cropped the way hyprpaper's "cover" mode does, then a clock
box is placed where the image is calmest (low saliency and texture), nudged toward the
rule-of-thirds points, away from the bar and from the stats window in the bottom-right
corner. It also reports whether light or dark text reads better there, and in the stats corner.

Output (all boxes as fractions of the screen):
    {"screens": {"eDP-1": {"clock": {"x": .., "y": .., "w": .., "h": ..}, "tone": "light",
                           "stats": {"tone": "light"}}}}
theme-apply.sh stores it next to the palette in the wallpaper's cache folder.
"""

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

WORK_WIDTH = 480
CLOCK_FRACTION = (0.24, 0.20)  # clock box as a fraction of screen width/height
STATS_BOX = (0.70, 0.76)  # the stats window occupies x >= 0.70 and y >= 0.76
BAR_FRACTION = 0.06  # keep clear of the top bar


def cover_crop(image: Image.Image, width: int, height: int) -> Image.Image:
    scale = max(width / image.width, height / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)), Image.LANCZOS
    )
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def spectral_residual(gray: np.ndarray) -> np.ndarray:
    """Hou & Zhang saliency: the log spectrum minus its local average marks the unusual parts."""
    spectrum = np.fft.fft2(gray)
    log_amplitude = np.log1p(np.abs(spectrum))
    phase = np.angle(spectrum)
    kernel = np.ones((3, 3)) / 9
    padded = np.pad(log_amplitude, 1, mode="edge")
    average = sum(
        padded[i : i + log_amplitude.shape[0], j : j + log_amplitude.shape[1]]
        * kernel[i, j]
        for i in range(3)
        for j in range(3)
    )
    saliency = np.abs(np.fft.ifft2(np.exp(log_amplitude - average + 1j * phase))) ** 2
    blurred = Image.fromarray(
        (saliency / saliency.max() * 255).astype(np.uint8)
    ).filter(ImageFilter.GaussianBlur(4))
    return np.asarray(blurred, dtype=np.float32) / 255


def color_contrast(crop: Image.Image) -> np.ndarray:
    """Achanta-style saliency: how far each blurred pixel's color is from the image's mean color.
    Catches large smooth subjects that texture and spectral residual miss."""
    ycc = np.asarray(
        crop.filter(ImageFilter.GaussianBlur(6)).convert("YCbCr"), dtype=np.float32
    )
    distance = np.linalg.norm(ycc - ycc.reshape(-1, 3).mean(0), axis=2)
    return distance / max(distance.max(), 1e-6)


def texture(gray: np.ndarray) -> np.ndarray:
    gy, gx = np.gradient(gray)
    energy = np.hypot(gx, gy)
    blurred = Image.fromarray(
        (energy / max(energy.max(), 1e-6) * 255).astype(np.uint8)
    ).filter(ImageFilter.GaussianBlur(3))
    return np.asarray(blurred, dtype=np.float32) / 255


def box_means(field: np.ndarray, box_w: int, box_h: int) -> np.ndarray:
    """Mean of field over every box_w x box_h window, via a summed-area table."""
    table = np.pad(field, ((1, 0), (1, 0))).cumsum(0).cumsum(1)
    sums = (
        table[box_h:, box_w:]
        - table[:-box_h, box_w:]
        - table[box_h:, :-box_w]
        + table[:-box_h, :-box_w]
    )
    return sums / (box_w * box_h)


def place(image: Image.Image, screen_w: int, screen_h: int) -> dict:
    work_h = round(WORK_WIDTH * screen_h / screen_w)
    crop = cover_crop(image, WORK_WIDTH, work_h)
    rgb = np.asarray(crop, dtype=np.float32) / 255
    gray = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)

    busy = (
        0.3 * spectral_residual(gray) + 0.3 * texture(gray) + 0.4 * color_contrast(crop)
    )
    box_w = round(WORK_WIDTH * CLOCK_FRACTION[0])
    box_h = round(work_h * CLOCK_FRACTION[1])
    cost = box_means(busy, box_w, box_h)

    rows, cols = cost.shape
    ys, xs = np.mgrid[0:rows, 0:cols]
    cx = (xs + box_w / 2) / WORK_WIDTH
    cy = (ys + box_h / 2) / work_h
    thirds = np.min(
        [np.hypot(cx - tx, cy - ty) for tx in (1 / 3, 2 / 3) for ty in (1 / 3, 2 / 3)],
        axis=0,
    )
    # Subjects tend to sit in the middle; prefer the calm space around them.
    centered = 1 - np.clip(np.hypot(cx - 0.5, cy - 0.5) / 0.5, 0, 1)
    cost = cost / max(cost.max(), 1e-6) + 0.35 * thirds + 0.3 * centered

    left, top = xs / WORK_WIDTH, ys / work_h
    right, bottom = (xs + box_w) / WORK_WIDTH, (ys + box_h) / work_h
    blocked = (top < BAR_FRACTION) | (left < 0.03) | (right > 0.97) | (bottom > 0.95)
    blocked |= (right > STATS_BOX[0]) & (bottom > STATS_BOX[1])
    cost[blocked] = np.inf

    y, x = np.unravel_index(np.argmin(cost), cost.shape)
    region = gray[y : y + box_h, x : x + box_w]
    corner = gray[round(work_h * STATS_BOX[1]) :, round(WORK_WIDTH * STATS_BOX[0]) :]
    return {
        "clock": {
            "x": round(x / WORK_WIDTH, 4),
            "y": round(y / work_h, 4),
            "w": CLOCK_FRACTION[0],
            "h": CLOCK_FRACTION[1],
        },
        "tone": "dark" if float(region.mean()) > 0.5 else "light",
        "stats": {"tone": "dark" if float(corner.mean()) > 0.5 else "light"},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("wallpaper", type=Path)
    parser.add_argument("out", type=Path)
    parser.add_argument(
        "--screen", action="append", required=True, help="NAME:WIDTHxHEIGHT (logical)"
    )
    args = parser.parse_args()

    image = Image.open(args.wallpaper).convert("RGB")
    screens = {}
    for spec in args.screen:
        name, size = spec.split(":", 1)
        width, height = (int(part) for part in size.lower().split("x"))
        screens[name] = place(image, width, height)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.out.with_suffix(".tmp")
    temporary.write_text(
        json.dumps({"wallpaper": str(args.wallpaper), "screens": screens}, indent=2)
    )
    temporary.replace(args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
