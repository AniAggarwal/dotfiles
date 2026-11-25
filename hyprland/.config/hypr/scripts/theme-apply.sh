#!/bin/bash
# theme-apply.sh <wallpaper-path>
# Generates (or restores from cache) the dune palette for a wallpaper,
# flips ~/.config/themes/current, and live-reloads apps.
set -euo pipefail
wp="$1"; [ -f "$wp" ] || exit 1
cache_root="$HOME/.cache/dune-theme"
stem="$(basename "${wp%.*}")-$(stat -c %Y "$wp")"
target="$cache_root/$stem"

if [ ! -d "$target" ]; then
    echo "theme-apply: cache miss, running matugen for $stem" >&2
    rm -rf "$cache_root/build"; mkdir -p "$cache_root/build"
    # --source-color-index 0: matugen 4.1 otherwise prompts interactively
    matugen image "$wp" -c "$HOME/.config/themes/dune/matugen.toml" \
        -t scheme-content --source-color-index 0
    mv "$cache_root/build" "$target"
else
    echo "theme-apply: cache hit for $stem" >&2
fi

# Desktop clock placement and stats-corner tone for this wallpaper, computed once and kept with
# its palette; a layout from before the stats tone existed is computed again.
if ! grep -q '"stats"' "$target/layout.json" 2>/dev/null; then
    screens=$(hyprctl monitors -j | jq -r '.[] | "--screen=\(.name):\((.width / .scale) | round)x\((.height / .scale) | round)"')
    # shellcheck disable=SC2086
    (uv run --script "$(dirname "$0")/wallpaper-layout.py" "$wp" "$target/layout.json" $screens >/dev/null 2>&1 &)
fi

ln -sfn "$target" "$HOME/.config/themes/current"
echo "$wp" > "$cache_root/last-wallpaper"

# live reloads (each best-effort)
pkill -SIGUSR1 kitty || true            # kitty reloads config in place
qs -c ani-bar ipc call bar reloadPalette >/dev/null 2>&1 || true
dunstctl reload || true
hyprctl reload || true
# GTK live nudge: flip color-scheme twice so running apps re-read named colors
{ gsettings set org.gnome.desktop.interface color-scheme 'default' &&
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'; } || true
notify-send "Dune theme" "Applied palette from $(basename "$wp")" || true
