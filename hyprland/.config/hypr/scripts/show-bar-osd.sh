#!/usr/bin/env bash
set -euo pipefail

kind="$1"
target="$2"
muted=false
case "$kind" in
    brightness)
        result=$(brightnessctl --class=backlight --machine-readable set "$target")
        IFS=, read -r _ _ _ percent _ <<< "$result"
        percent="${percent%%%}"
        ;;
    sink|source)
        result=$(wpctl get-volume "$target")
        read -r _ volume marker <<< "$result"
        percent=$(awk -v v="$volume" 'BEGIN { printf "%d", v * 100 + 0.5 }')
        if [[ "$marker" == "[MUTED]" ]]; then muted=true; fi
        ;;
    *) exit 2 ;;
esac

[[ "$percent" =~ ^[0-9]+$ ]] || exit 1
qs -c ani-bar ipc call osd display "$kind" "$percent" "$muted" >/dev/null 2>&1 || true
