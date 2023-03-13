sudo chmod 646 /sys/class/backlight/intel_backlight/brightness
# If brightness is greater than 4, set it to 0
# Else, add 1 to the current brightness
current_brightness=$(cat /sys/class/backlight/intel_backlight/brightness)

echo $((current_brightness + 1)) | tee /sys/class/backlight/intel_backlight/brightness
