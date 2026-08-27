#!/usr/bin/env python3
"""Generate a truecolor half-block Fastfetch logo from a reference image."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Convert an image into a truecolor Unicode half-block logo for "
            "Fastfetch."
        ),
        epilog=(
            "Example: %(prog)s reference.png "
            "--output dune-logo.ansi --width 96 --pixel-height 42"
        ),
    )
    parser.add_argument(
        "input",
        type=Path,
        help="reference image to convert",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("dune-logo.ansi"),
        help="output file containing raw ANSI art (default: dune-logo.ansi)",
    )
    parser.add_argument(
        "--width",
        type=int,
        default=96,
        help="output width in terminal cells (default: 96)",
    )
    parser.add_argument(
        "--pixel-height",
        type=int,
        default=42,
        help=(
            "source pixels represented vertically; must be even "
            "(default: 42)"
        ),
    )
    parser.add_argument(
        "--fade-pixels",
        type=int,
        default=4,
        help="edge width of the vignette in source pixels (default: 4)",
    )
    parser.add_argument(
        "--vignette-strength",
        type=float,
        default=0.18,
        help=(
            "maximum blend toward black at the edge, from 0 to 1 "
            "(default: 0.18)"
        ),
    )
    parser.add_argument(
        "--trim-threshold",
        type=int,
        default=20,
        help=(
            "non-white difference required when trimming the image border "
            "(default: 20)"
        ),
    )
    parser.add_argument(
        "--white-edge-threshold",
        type=int,
        default=225,
        help=(
            "repair perimeter pixels at or above this RGB threshold by "
            "continuing adjacent artwork (default: 225)"
        ),
    )
    return parser.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    if args.width < 1:
        raise SystemExit("--width must be positive")
    if args.pixel_height < 2 or args.pixel_height % 2:
        raise SystemExit("--pixel-height must be an even number >= 2")
    if args.fade_pixels < 0:
        raise SystemExit("--fade-pixels cannot be negative")
    if not 0 <= args.vignette_strength <= 1:
        raise SystemExit("--vignette-strength must be between 0 and 1")
    if not 0 <= args.trim_threshold <= 255:
        raise SystemExit("--trim-threshold must be between 0 and 255")
    if not 0 <= args.white_edge_threshold <= 255:
        raise SystemExit("--white-edge-threshold must be between 0 and 255")


def trim_white_border(image: Image.Image, threshold: int) -> Image.Image:
    background = Image.new("RGB", image.size, (255, 255, 255))
    difference = ImageChops.difference(image, background).convert("L")
    mask = difference.point(lambda value: 255 if value > threshold else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise SystemExit("input image has no non-white content")
    return image.crop(bounds)


def repair_white_edge_tiles(
    image: Image.Image,
    threshold: int,
) -> tuple[Image.Image, int]:
    """Continue nearby artwork through accidental near-white perimeter tiles."""
    source = image.copy()
    pixels = image.load()
    source_pixels = source.load()
    width, height = image.size
    repaired = 0

    def near_white(pixel: tuple[int, int, int]) -> bool:
        return min(pixel) >= threshold

    for y in range(height):
        for x in range(width):
            if x not in (0, width - 1) and y not in (0, height - 1):
                continue
            if not near_white(source_pixels[x, y]):
                continue

            inward_x = 1 if x == 0 else width - 2 if x == width - 1 else x
            inward_y = 1 if y == 0 else height - 2 if y == height - 1 else y
            pixels[x, y] = source_pixels[inward_x, inward_y]
            repaired += 1

    return image, repaired


def darken_edge(
    pixel: tuple[int, int, int],
    x: int,
    y: int,
    width: int,
    height: int,
    fade_pixels: int,
    vignette_strength: float,
) -> tuple[int, int, int]:
    if fade_pixels == 0:
        return pixel

    distance = min(x, y, width - 1 - x, height - 1 - y)
    edge_fraction = max(0.0, (fade_pixels - distance) / fade_pixels)
    strength = edge_fraction * vignette_strength
    return tuple(round(channel * (1.0 - strength)) for channel in pixel)


def ansi_foreground(pixel: tuple[int, int, int]) -> str:
    red, green, blue = pixel
    return f"\033[38;2;{red};{green};{blue}m"


def ansi_background(pixel: tuple[int, int, int]) -> str:
    red, green, blue = pixel
    return f"\033[48;2;{red};{green};{blue}m"


def generate_logo(args: argparse.Namespace) -> int:
    image = Image.open(args.input).convert("RGB")
    image = trim_white_border(image, args.trim_threshold).resize(
        (args.width, args.pixel_height),
        Image.Resampling.LANCZOS,
    )
    image, repaired_edges = repair_white_edge_tiles(
        image,
        args.white_edge_threshold,
    )
    pixels = image.load()
    lines: list[str] = []

    for y in range(0, args.pixel_height, 2):
        line: list[str] = []
        for x in range(args.width):
            top = darken_edge(
                pixels[x, y],
                x,
                y,
                args.width,
                args.pixel_height,
                args.fade_pixels,
                args.vignette_strength,
            )
            bottom = darken_edge(
                pixels[x, y + 1],
                x,
                y + 1,
                args.width,
                args.pixel_height,
                args.fade_pixels,
                args.vignette_strength,
            )
            line.append(ansi_foreground(top))
            line.append(ansi_background(bottom))
            line.append("▀")
        line.append("\033[0m\n")
        lines.append("".join(line))

    args.output.write_bytes("".join(lines).encode("utf-8"))
    print(
        f"Wrote {args.output} "
        f"({args.width} columns x {args.pixel_height // 2} rows, "
        f"{args.output.stat().st_size} bytes; "
        f"repaired {repaired_edges} perimeter tiles)"
    )
    return 0


def main() -> int:
    args = parse_args()
    validate_args(args)
    return generate_logo(args)


if __name__ == "__main__":
    raise SystemExit(main())
