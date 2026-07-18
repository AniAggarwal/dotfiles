#!/bin/bash
# Boot restore: re-apply the last picked wallpaper + theme.
# Reads ~/.cache/dune-theme/last-wallpaper; exits silently if absent.

last_file="$HOME/.cache/dune-theme/last-wallpaper"

[ -f "$last_file" ] || exit 0
wallpaper=$(<"$last_file")
[ -f "$wallpaper" ] || exit 0

# Wait for hyprpaper's IPC to come up (it is started by the same autostart).
# hyprpaper >= 0.8 has no preload/listloaded; "wallpaper" loads the image itself.
for _ in $(seq 1 50); do
    hyprctl hyprpaper listactive &>/dev/null && break
    sleep 0.2
done

hyprctl hyprpaper wallpaper ",$wallpaper"

"$HOME/.config/hypr/scripts/theme-apply.sh" "$wallpaper"
