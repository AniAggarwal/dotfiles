#!/bin/bash
# NetworkManager dispatcher script - refreshes waybar on network changes
# Symlink to: /etc/NetworkManager/dispatcher.d/99-waybar-network
pkill -SIGRTMIN+4 waybar 2>/dev/null
