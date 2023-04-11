# If brightness is greater than 4, set it to 0
# Else, add 1 to the current brightness
current_brightness=$(cat /sys/class/backlight/intel_backlight/brightness)

if [ $current_brightness -ge 4 ]; then
    echo 0 | tee /sys/class/backlight/intel_backlight/brightness
else
    echo $((current_brightness + 1)) | tee /sys/class/backlight/intel_backlight/brightness
fi
