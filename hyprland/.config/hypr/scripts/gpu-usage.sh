#!/bin/bash
GPU_PCI="0000:01:00.0"

# Check if GPU exists
if [[ ! -d "/sys/bus/pci/devices/$GPU_PCI" ]]; then
    echo '{"text": "󰚦", "tooltip": "dGPU disabled (right-click to enable)"}'
    exit 0
fi

status=$(cat "/sys/bus/pci/devices/$GPU_PCI/power/runtime_status" 2>/dev/null)
if [[ "$status" == "active" ]]; then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "?")
    echo "{\"text\": \"${usage}%\", \"tooltip\": \"dGPU active (right-click to disable)\"}"
else
    echo '{"text": "󰒲", "tooltip": "dGPU suspended (right-click to disable)"}'
fi
