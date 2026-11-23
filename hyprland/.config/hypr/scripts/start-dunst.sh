#!/bin/sh
# Starts dunst at the "Reduced" level (pause level 25, the ani-bar notification levels).
# Waits for dunst to own the bus name before setting it; asking earlier would make D-Bus
# activate a second dunst.
dunst -config ~/.config/dunst/dunstrc &
for _ in $(seq 50); do
    if busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
        NameHasOwner s org.freedesktop.Notifications 2>/dev/null | grep -q true; then
        dunstctl set-pause-level 25
        break
    fi
    sleep 0.1
done
wait
