#!/bin/bash

# Get the name of the running sink
running_sink=$(pactl list short sinks | awk '$7 == "RUNNING" { print $2; exit }')

# Check if a running sink was found
if [ -n "$running_sink" ]; then
    # Use pactl to list sinks and search for the given sink name
    object_id=$(pactl list sinks | awk -v name="$running_sink" '$2 == name { found = 1 } found && $1 == "object.id" { print $3; exit }')
    
    # Check if the object_id was found
    if ! [ -n "$object_id" ]; then
        echo "Sink '$running_sink' not found."
        exit 1
    fi

object_id=$(echo "$object_id" | tr -d '"')
else
    echo "No running sink found. Using default"
    object_id="@DEFAULT_SINK@"
fi
