#!/bin/bash

WALLPAPER_DIR="$HOME/data/photos/dune-wallpapers"

# Build indexed arrays for reliable path lookup
shopt -s nullglob
paths=()
entries=""

for img in "$WALLPAPER_DIR"/*.{jpg,png,jpeg,webp}; do
    name="${img##*/}"
    name="${name%.*}"
    # Prettify: hyphens to spaces, title case
    pretty=$(echo "$name" | sed 's/-/ /g; s/\b\w/\u&/g')
    paths+=("$img")
    [ -n "$entries" ] && entries+="\n"
    entries+="${pretty}\0icon\x1f${img}"
done

[ ${#paths[@]} -eq 0 ] && notify-send "Wallpaper Picker" "No wallpapers found in $WALLPAPER_DIR" && exit 1

# Show rofi picker with image previews, return selected index
selected=$(echo -en "$entries" | rofi \
    -theme ~/.config/rofi/wallpaper-picker.rasi \
    -dmenu \
    -p "Wallpaper" \
    -format i \
    -show-icons)

[ -z "$selected" ] && exit 0

wallpaper="${paths[$selected]}"
[ -f "$wallpaper" ] || exit 1

# Set wallpaper via hyprpaper
hyprctl hyprpaper preload "$wallpaper"
hyprctl hyprpaper wallpaper ",$wallpaper"
