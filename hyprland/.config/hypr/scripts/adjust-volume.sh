#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source|sink> <percentage>%+|-"
    exit 1
fi

# Get the source/sink and volume adjustment percentage from the arguments
device="$1"
adjustment="$2"


# Validate the device format
if ! [[ "$device" =~ ^(source)|(sink)$ ]]; then
    echo "Invalid device format. Please use source or sink."
    exit 1
fi

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

# # Send a notification with the new volume
# # first get current volume
# volume_str=$(wpctl get-volume $object_id)
# # volume in format: Volume: 0.15 [MUTED]
# volume_str=$(echo $volume_str | awk '{print $2*100"%"}')
#
# # if muted, add 󰖁, else add 󰕾
# if [[ $volume_str == *"MUTED"* ]]; then
#     volume_str="$volume_str 󰖁 "
# else
#     volume_str="$volume_str 󰕾 "
# fi
#
# notify-send -t 300 "$volume_str"
