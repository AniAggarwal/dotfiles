#!/bin/sh
# idle-step.sh dim|undim|screen-off|suspend
#
# The hypridle steps that Keep Awake (the bar's toggle) skips: dimming the screen and keyboard,
# turning the screen off, and suspending. The lock is not here: it runs either way.
#
# Keep Awake is a flag file rather than a systemd idle inhibitor because hypridle honors an
# inhibitor by skipping every step, the lock included, and the per-listener ignore_inhibit
# would also ignore apps that hold one on purpose (a playing video).
state="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ani-bar"
awake="$state/keep-awake"
# Set only when this script dimmed, so undim never restores a stale saved brightness.
dimmed="$state/dimmed"

case "$1" in
dim)
    [ -e "$awake" ] && exit 0
    mkdir -p "$state"
    brightnessctl -s set 10                 # backlight to minimum; 0 is black on the OLED panel
    brightnessctl -sd dell::kbd_backlight set 0
    touch "$dimmed"
    ;;
undim)
    [ -e "$dimmed" ] || exit 0
    rm -f "$dimmed"
    brightnessctl -r
    brightnessctl -rd dell::kbd_backlight
    ;;
screen-off)
    [ -e "$awake" ] || hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'
    ;;
suspend)
    [ -e "$awake" ] || systemctl suspend
    ;;
*)
    echo "usage: idle-step.sh dim|undim|screen-off|suspend" >&2
    exit 2
    ;;
esac
