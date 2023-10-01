#!/bin/bash

# Check if Ethernet is connected
if nmcli -t -f TYPE,DEVICE con show --active | grep -q "ethernet"; then
    # Ethernet is connected, disable Wi-Fi
    nmcli radio wifi off
    echo "Ethernet is connected, disabling Wi-Fi" > /tmp/wifi-toggle.log
else
    # Ethernet is not connected, enable Wi-Fi
    nmcli radio wifi on
    echo "Ethernet is not connected, enabling Wi-Fi" > /tmp/wifi-toggle.log
fi
