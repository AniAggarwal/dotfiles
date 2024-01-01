#!/usr/bin/env bash

echo "running 99-toggle-wifi script" > /tmp/99-toggle-wifi.log

if [ "$2" = "up" ] || [ "$2" = "down" ]; then
    echo "Wifi is $2" > /tmp/99-toggle-wifi.log
    # Execute the wifi_toggle.sh script
    /bin/bash /home/ani/bin/wifi-toggle.sh
fi
