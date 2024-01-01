#!/bin/bash

# Get the name of the running sources
running_source=$(pactl list short sources | awk '$7 == "RUNNING" { print $2; exit }')

# Check if a running source was found
if [ -n "$running_source" ]; then
    # Use pactl to list sources and search for the given source name
    object_id=$(pactl list sources | awk -v name="$running_source" '$2 == name { found = 1 } found && $1 == "object.id" { print $3; exit }')
    
    # Check if the object_id was found
    if ! [ -n "$object_id" ]; then
        echo "Source '$running_source' not found."
        exit 1
    fi

object_id=$(echo "$object_id" | tr -d '"')
else
    echo "No running source found. Using default"
    object_id="@DEFAULT_SOURCE@"
fi
