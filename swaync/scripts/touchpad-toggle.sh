#!/bin/bash
# Requires jq. Finds your touchpad's device name via hyprctl and flips it on/off.
STATE_FILE="$HOME/.cache/swaync-touchpad-state"
DEVICE=$(hyprctl devices -j 2>/dev/null | jq -r '.mice[] | select(.name | test("touchpad"; "i")) | .name' | head -n1)

if [ -z "$DEVICE" ]; then
    notify-send -a "Quick Settings" "Touchpad" "No touchpad device found" -t 2000
    exit 1
fi

if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "disabled" ]; then
    hyprctl keyword device:"$DEVICE":enabled true > /dev/null
    echo "enabled" > "$STATE_FILE"
    notify-send -a "Quick Settings" "Touchpad" "Enabled" -t 1500
else
    hyprctl keyword device:"$DEVICE":enabled false > /dev/null
    echo "disabled" > "$STATE_FILE"
    notify-send -a "Quick Settings" "Touchpad" "Disabled" -t 1500
fi
