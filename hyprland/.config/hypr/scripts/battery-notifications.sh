#!/bin/env bash

APPNAME="Battery Notifications"
CATEGORY_PLUGGED="battery"
CATEGORY_LEVEL="system"
# Battery level thresholds (in percent)
LOW_THRESHOLD=25
VERY_LOW_THRESHOLD=10
CRITICAL_THRESHOLD=5

# Status names (as provided by your system via upower or ACPI)
DISCHARGING="Discharging"
CHARGING="Charging"
PLUGGED="Not charging"
FULL="Full"

# Initialize previous plug status and percentage.
prev_plug_status="unknown"
prev_percentage=100

# Track the last notified battery level category:
# "none" (no alert sent), "low", "very_low", or "critical"
last_notified_level="none"

# Function to send notifications via dunst
notify() {
    urgency="$1"
    title="$2"
    message="$3"
    category="$4"
    dunstify -u "$urgency" -a "$APPNAME" -c "$category" "$title" "$message"
}

# Use UPower to monitor battery details in an event-driven fashion.
upower --monitor-detail | while read -r line; do
    # Refresh waybar battery module on any battery event
    pkill -SIGRTMIN+3 waybar 2>/dev/null

    # Process state changes.
    if [[ "$line" =~ "state:" ]]; then
        # Extract the state value (e.g. "charging", "discharging", etc.)
        current_state=$(echo "$line" | awk '{print $2}')
        # Capitalize the first letter to match our defined status names.
        current_state="$(echo "$current_state" | sed 's/^\(.\)/\U\1/')"

        if [[ "$current_state" != "$prev_plug_status" ]]; then
            if [[ "$current_state" == "$CHARGING" || "$current_state" == "$FULL" ]]; then
                notify low "Battery Charging" "Battery is now charging." $CATEGORY_PLUGGED"
                # Reset the last notification when state changes.
                last_notified_level="none"
            elif [[ "$current_state" == "$DISCHARGING" ]]; then
                notify low "Battery Unplugged" "Battery is now discharging." $CATEGORY_PLUGGED"
                last_notified_level="none"
            fi
            prev_plug_status="$current_state"
        fi
    fi

    # Process percentage updates.
    if [[ "$line" =~ "percentage:" ]]; then
        # Extract numeric percentage (removing the trailing % if present)
        current_percentage=$(echo "$line" | awk '{print $2}' | tr -d '%')
        
        if [[ "$prev_plug_status" == "$DISCHARGING" ]]; then
            # Determine the current alert category based on battery level.
            current_category="none"
            if (( current_percentage <= CRITICAL_THRESHOLD )); then
                current_category="critical"
            elif (( current_percentage <= VERY_LOW_THRESHOLD )); then
                current_category="very_low"
            elif (( current_percentage <= LOW_THRESHOLD )); then
                current_category="low"
            fi

            # Only send a notification if we've crossed into a new category.
            if [[ "$current_category" != "none" && "$current_category" != "$last_notified_level" ]]; then
                if [[ "$current_category" == "critical" ]]; then
                    notify critical "Critical Battery" "Battery level is ${current_percentage}%" "$CATEGORY_LEVEL"
                elif [[ "$current_category" == "very_low" ]]; then
                    notify critical "Very Low Battery" "Battery level is ${current_percentage}%" "$CATEGORY_LEVEL"
                elif [[ "$current_category" == "low" ]]; then
                    notify normal "Low Battery" "Battery level is ${current_percentage}%" "$CATEGORY_LEVEL"
                fi
                last_notified_level="$current_category"
            fi
        fi
        
        prev_percentage="$current_percentage"
    fi
done
