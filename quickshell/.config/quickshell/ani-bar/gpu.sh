#!/bin/sh
# Discrete GPU readings for the bar.
#   gpu.sh state      -> absent | suspended | active   (sysfs only, never wakes the GPU)
#   gpu.sh telemetry  -> "util, temp, mem used MiB, mem total MiB, watts" while active, else nothing
#   gpu.sh apps       -> "pid, process, used MiB" per compute app while active, else nothing
export LC_ALL=C
device=/sys/bus/pci/devices/0000:01:00.0

state() {
    if [ ! -d "$device" ]; then
        echo absent
    elif [ "$(cat "$device/power/runtime_status" 2>/dev/null)" = active ]; then
        echo active
    else
        echo suspended
    fi
}

case $1 in
    state) state ;;
    telemetry)
        [ "$(state)" = active ] || exit 0
        exec nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw \
            --format=csv,noheader,nounits ;;
    apps)
        [ "$(state)" = active ] || exit 0
        exec nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader,nounits ;;
    *) echo "usage: gpu.sh state|telemetry|apps" >&2; exit 2 ;;
esac
