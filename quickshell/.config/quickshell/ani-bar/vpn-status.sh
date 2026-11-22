#!/bin/sh
export LC_ALL=C
# The Proton clients use proton0. Ignore the dummy kill-switch connections.
if nmcli -w 2 -t -e no -f TYPE,STATE,DEVICE,NAME connection show --active 2>/dev/null |
    awk -F: '$2 == "activated" && $1 ~ /^(vpn|tun|wireguard)$/ && ($3 == "proton0" || tolower($4) ~ /^protonvpn /) { found=1 } END { exit !found }'; then
    echo 'Proton VPN'
elif pgrep -ix Windscribe >/dev/null && timeout 3 windscribe-cli status 2>/dev/null |
    awk '/^[[:space:]]*Connection:[[:space:]]*Connected to / { found=1 } END { exit !found }'; then
    echo Windscribe
fi
