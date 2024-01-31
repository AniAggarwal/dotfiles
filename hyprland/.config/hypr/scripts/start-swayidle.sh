#!/usr/bin/env bash

lock_script="$HOME/.config/hypr/scripts/lock-screen.sh"
lock_timeout=180
off_timeout=300

swayidle -w \
    timeout "$(($lock_timeout - 5))" "notify-send 'Locking screen in 5 seconds'" \
    timeout $lock_timeout "$lock_script" \
    timeout $off_timeout 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on && notify-send "the sleeper must awaken"' \
    before-sleep "$lock_script" \
