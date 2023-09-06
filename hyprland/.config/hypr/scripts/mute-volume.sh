#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source|sink> <0|1|toggle>"
    exit 1
fi

# Get the source/sink and adjustment from the arguments
device="$1"
adjustment="$2"

# Validate the device format
if ! [[ "$device" =~ ^(source)|(sink)$ ]]; then
    echo "Invalid device format. Please use source or sink."
    exit 1
fi

# Check if the input is valid
if ! [[ "$adjustment" =~ ^(0|1|toggle)$ ]]; then
    echo "Invalid input. Please use 0, 1, or toggle."
    exit 1
fi

# Get the running sink
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$device" = "source" ]; then
    source "$script_dir/get-running-source.sh"
else 
    source "$script_dir/get-running-sink.sh"
fi

# Adjust the volume of the running sink using wpctl
wpctl set-mute $object_id $adjustment
