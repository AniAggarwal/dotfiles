#!/bin/sh
mon1="DP-3" # Primary monitor
mon2="DP-2" # Secondary
ws_limit=4 # how many workspaces on the primary monitor
 
handleworkspaces() {
    if [[ ${1:0:15} == "createworkspace" ]]; then
        ws=$(( ${1:17:19} ))
        if (( $(($ws <= $ws_limit)) )); then
            hyprctl dispatch moveworkspacetomonitor "$ws $mon1"
        else
            hyprctl dispatch moveworkspacetomonitor  "$ws $mon2"
        fi
    elif [[ ${1:0:9} == "workspace" ]]; then
        ws=$(( ${1:11:13} ))
        if (( $(($ws <= $ws_limit)) )); then
            hyprctl dispatch moveworkspacetomonitor  "$ws $mon1"
        else
            hyprctl dispatch moveworkspacetomonitor  "$ws $mon2"
        fi
    fi
}
 
socat - UNIX-CONNECT:/tmp/hypr/$(echo $HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock | while read line; do handleworkspaces $line; done
