#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source|sink> <percentage>%+|-"
    exit 1
fi

# Get the source/sink and volume adjustment percentage from the arguments
device="$1"
adjustment="$2"

# Validate the adjustment format (N%+ or N%-)
if ! [[ "$adjustment" =~ ^[0-9]+%[-+]$ ]]; then
    echo "Invalid adjustment format. Please use N%+ or N%- (e.g., 5%+ or 10%-)."
    exit 1
fi

# Get the running source/sink
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$device" = "source" ]; then
    source "$script_dir/get-running-source.sh"
else 
    source "$script_dir/get-running-sink.sh"
fi

# Adjust the volume of the running sink using wpctl
echo "wpctl set-volume -l 1.0 $object_id $adjustment"
wpctl set-volume -l 1.0 $object_id $adjustment
