#!/bin/sh

# first calls swaylock then waits and suspend-then-hibernates the system
swaylock -f --config ~/.config/swaylock-effects/config

# wait for 5 minutes before suspending
# sleep 300
# systemctl suspend-then-hibernate
