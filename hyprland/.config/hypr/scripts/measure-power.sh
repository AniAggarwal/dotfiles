#!/bin/bash
# Standardized power measurement script
# Usage: ./measure-power.sh [label]
# Example: ./measure-power.sh "waybar-optimized"

set -e

MEASURE_DIR="$HOME/data/powertop-measurements"
LABEL="${1:-manual}"
KERNEL=$(uname -r)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FILENAME="${KERNEL}_${LABEL}_${TIMESTAMP}"

# Gather system state
echo "=== Power Measurement: $FILENAME ==="
echo ""

# Current power draw
POWER=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "energy-rate" | awk '{print $2}')
echo "Current discharge rate: ${POWER} W"

# System state
echo ""
echo "System state:"
echo "  Kernel: $KERNEL"
echo "  Bluetooth: $(rfkill list bluetooth | grep -q "Soft blocked: yes" && echo "off" || echo "on")"
echo "  WiFi: $(nmcli radio wifi)"
echo "  GPU: $(cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status)"
echo "  Screen brightness: $(cat /sys/class/backlight/*/brightness | head -1)"
echo "  CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"

# Ask to run powertop
echo ""
read -p "Run 60s powertop measurement? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running powertop for 60s... (don't touch anything)"
    sudo powertop --html="$MEASURE_DIR/${FILENAME}.html" --time=60
    echo ""
    echo "Saved: $MEASURE_DIR/${FILENAME}.html"

    # Extract discharge rate from report
    MEASURED=$(grep -o "discharge rate of:.*W" "$MEASURE_DIR/${FILENAME}.html" | grep -oP '[\d.]+(?=\s*W)')
    echo "Measured discharge rate: ${MEASURED} W"
fi

echo ""
echo "=== Done ==="
