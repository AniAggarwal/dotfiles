#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <percentage>+|-"
    exit 1
fi

# Get the volume adjustment percentage from the argument
adjustment="$1"

# Validate the adjustment format (N%+ or N%-)
if ! [[ "$adjustment" =~ ^[0-9]+%[-+]$ ]]; then
    echo "Invalid adjustment format. Please use N%+ or N%- (e.g., 5%+ or 10%-)."
    exit 1
fi

# Get the running sink
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/get-running-sink.sh"

# Adjust the volume of the running sink using wpctl
echo "wpctl set-volume -l 1.0 $object_id $adjustment" > /tmp/foo.txt
wpctl set-volume -l 1.0 $object_id $adjustment
