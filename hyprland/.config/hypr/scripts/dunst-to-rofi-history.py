#!/usr/bin/env python3
import subprocess
import json
import html
import os

# --- CONFIGURATION ---
THEME_FILE = "~/.config/rofi/rofi-config.rasi"


def run_command(command):
    """Executes a shell command and returns its stdout."""
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, check=True, shell=False
        )
        return result.stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        # If a command fails, show an error in rofi and exit gracefully.
        rofi_error(f"Error executing: {' '.join(command)}\n{e}")
        exit(1)


def rofi_menu(prompt, options, markup=False):
    """Displays a rofi menu and returns the user's selection."""
    theme_path = os.path.expanduser(THEME_FILE)
    command = ["rofi", "-dmenu", "-p", prompt, "-i", "-theme", theme_path]
    if markup:
        command.append("-markup-rows")

    input_str = "\n".join(options)
    result = subprocess.run(
        command, input=input_str, capture_output=True, text=True, shell=False
    )
    return result.stdout.strip()


def rofi_error(message):
    """Displays an error message using rofi."""
    theme_path = os.path.expanduser(THEME_FILE)
    subprocess.run(["rofi", "-e", message, "-theme", theme_path], shell=False)


def get_ignored_appnames():
    """Parses dunst rules to find appnames with history_ignore or skip_display."""
    ignored = set()
    try:
        rules_json = run_command(["dunstctl", "rules", "--json"])
        rules_data = json.loads(rules_json)
        # The rules data is nested under a 'rules' key
        for rule in rules_data.get("rules", []):
            if rule.get("history_ignore") or rule.get("skip_display"):
                ignored.add(rule.get("appname"))
    except json.JSONDecodeError:
        rofi_error("Failed to parse dunst rules JSON.")
    return ignored


def main():
    """Main script logic."""
    ignored_appnames = get_ignored_appnames()

    # 1. Get and filter notifications
    try:
        history_json = run_command(["dunstctl", "history", "-f", "json"])
        history_data = json.loads(history_json)
    except json.JSONDecodeError:
        rofi_error("Failed to parse dunst history JSON.")
        return

    # A reliable mapping from the string rofi will display to the notification's data
    notification_map = {}
    rofi_options = []

    # The history data is nested under 'data' and is a list containing one list of notifications
    notifications = history_data.get("data", [[]])[0]

    for notif in reversed(notifications):  # Newest first
        appname = notif.get("appname", {}).get("data", "N/A")

        if appname in ignored_appnames:
            continue

        # Escape HTML special characters to prevent rendering issues in rofi
        summary = html.escape(notif.get("summary", {}).get("data", ""))
        body = html.escape(notif.get("body", {}).get("data", ""))

        # This is the string that will be displayed in the rofi menu
        display_string = (
            f"<b>{summary}</b>\n<i><small>{appname}: {body}</small></i>"
        )

        notification_map[display_string] = notif
        rofi_options.append(display_string)

    if not rofi_options:
        rofi_error("No notification history.")
        return

    # 2. Show the notification list in rofi
    selected_string = rofi_menu("🔔 History", rofi_options, markup=True)

    if not selected_string:  # User pressed escape
        return

    # 3. Get the selected notification's data using the map
    selected_notification = notification_map.get(selected_string)
    if not selected_notification:
        return  # Should not happen, but good practice to check

    notification_id = selected_notification.get("id", {}).get("data")

    # 4. Show the action menu
    actions = [" Dismiss", " Copy Body", " Pop (Re-show)"]
    chosen_action = rofi_menu("Action", actions)

    if not chosen_action:
        return

    # 5. Perform the action
    if chosen_action == " Dismiss":
        run_command(["dunstctl", "history-rm", str(notification_id)])
    elif chosen_action == " Copy Body":
        body_to_copy = selected_notification.get("body", {}).get("data", "")
        subprocess.run(["wl-copy"], input=body_to_copy, text=True, shell=False)
    elif chosen_action == " Pop (Re-show)":
        run_command(["dunstctl", "history-pop"])


if __name__ == "__main__":
    main()
