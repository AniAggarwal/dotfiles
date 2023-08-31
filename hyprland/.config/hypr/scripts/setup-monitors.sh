#!/bin/bash

# Run hyprctl monitors and store the output in a variable
output=$(hyprctl monitors)

# Initialize an empty string to hold the port
port=""

# Parse the output line by line
while IFS= read -r line; do
  # Look for lines starting with "Monitor"
  if [[ "$line" =~ ^Monitor\ (.*)\ \(ID ]]; then
    # Extract the port name (e.g., eDP-1, DP-7, etc.)
    extracted_port="${BASH_REMATCH[1]}"

    # Skip eDP-1, look for other ports
    if [ "$extracted_port" != "eDP-1" ]; then
      port="$extracted_port"
      break
    fi
  fi
done <<< "$output"

# Check if a port other than eDP-1 was found
if [ -z "$port" ]; then
  echo "No port other than eDP-1 was found."
  exit 1
fi

# Run hyprctl keyword monitor command with the found port
hyprctl keyword monitor "$port, 2560x1440@165, 0x0, 1"

