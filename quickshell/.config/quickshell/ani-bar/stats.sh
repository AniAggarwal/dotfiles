#!/bin/sh
# One sample of the counters the bar shows, as "key value..." lines.
export LC_ALL=C
head -n1 /proc/stat
awk '/^MemTotal:/ { total = $2 } /^MemAvailable:/ { available = $2 } END { print "mem", total, available }' /proc/meminfo
read -r load _ < /proc/loadavg && echo "load $load"
read -r uptime _ < /proc/uptime && echo "uptime $uptime"
echo "threads $(nproc)"
for dir in /sys/class/hwmon/hwmon*; do
    case $(cat "$dir/name") in
        coretemp|k10temp) echo "cputemp $(cat "$dir/temp1_input")" ;;
        nvme) echo "nvmetemp $(cat "$dir/temp1_input")" ;;
    esac
done 2>/dev/null
echo "gpu $(sh "$(dirname "$0")/gpu.sh" state)"
for backlight in /sys/class/backlight/*; do
    [ -r "$backlight/brightness" ] || continue
    echo "brightness $(( $(cat "$backlight/brightness") * 100 / $(cat "$backlight/max_brightness") ))%"
    break
done
