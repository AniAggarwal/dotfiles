import subprocess
import re

name_to_config = {
    "Dell Inc. Dell S2417DG #ASOhOJsjs/Td": "2560x1440@165, 0x0, 1",
}
desc_pattern = r"description: ([^\n(]+)(?: \([^)]+\))?\n"
monitor_pattern = r"^Monitor (.*) \(ID"

# Run the 'hyprctl monitors' command and capture its output
output = subprocess.getoutput("hyprctl monitors")

# Initialize variables to hold the port and a flag for checking the next line for description
port = ""
check_next_line = False
monitor_name = None

# Loop through each line in the output
for line in output.split("\n"):
    # If the flag is set, check the line for description
    if check_next_line:
        if "description:" in line:
            match = re.findall(desc_pattern, line)
            if match:
                monitor_name = match[0]
            break
        else:
            port = ""  # Reset port if description doesn't match

    # Check if the line starts with "Monitor"
    match = re.match(monitor_pattern, line)
    if match:
        extracted_port = match.group(1)

        # Skip eDP-1 and look for other ports
        if extracted_port != "eDP-1":
            port = extracted_port
            check_next_line = (
                True  # Set flag to check the next line for description
            )
        else:
            check_next_line = False

# Check if a suitable port was found
if not port or monitor_name is None:
    print("No suitable port was found.")
else:
    # Run the 'hyprctl keyword monitor' command with the found port
    cmd = f'hyprctl keyword monitor "{port}, {name_to_config[monitor_name]}"'
    # subprocess.run(cmd, shell=True)
    print(cmd)
