#!/bin/sh
# One sample of the counters the bar shows, as "key value..." lines.
export LC_ALL=C
head -n1 /proc/stat
awk '/^MemTotal:/ { total = $2 } /^MemAvailable:/ { available = $2 } /^SwapTotal:/ { swap = $2 } /^SwapFree:/ { swapfree = $2 }
    END { print "mem", total, available; print "swap", swap, swapfree }' /proc/meminfo
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | awk '{ sum += $1; n++ } END { if (n) print "cpufreq", sum / n }'
# Bytes moved by real interfaces (not loopback, containers or bridges), for throughput deltas.
awk 'NR > 2 { sub(/:/, " "); if ($1 !~ /^(lo|docker|veth|br-|virbr)/) { rx += $2; tx += $10 } } END { print "net", rx + 0, tx + 0 }' /proc/net/dev
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
