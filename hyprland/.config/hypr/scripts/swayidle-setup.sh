#!/bin/sh

# TODO: figure out how to make display turn of
# timeout 600 'swaymsg "output * dpms off"' \

# After 5 min of inactivity, lock the screen and turn off the display
# After another 5 minutes suspend-then-hibernate the system
swayidle -w \
    timeout 300 'swaylock -f --config ~/.config/swaylock-effects/config' \
    timeout 300 'systemctl suspend-then-hibernate' \
