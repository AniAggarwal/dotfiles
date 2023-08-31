#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <0|1|toggle>"
    exit 1
fi

# Get the input argument
adjustment="$1"

# Check if the input is valid
if ! [[ "$adjustment" =~ ^(0|1|toggle)$ ]]; then
    echo "Invalid input. Please use 0, 1, or toggle."
    exit 1
fi

# Get the running sink
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/get-running-sink.sh"

# Adjust the volume of the running sink using wpctl
wpctl set-mute $object_id $adjustment
