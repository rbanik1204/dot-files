#!/bin/bash
DEVICE=$(brightnessctl -l 2>/dev/null | grep -i "kbd_backlight" | grep -oP "'\K[^']+" | head -n1)
if [ -z "$DEVICE" ]; then
    notify-send -a "Quick Settings" "Keyboard Backlight" "No device found" -t 2000
    exit 1
fi
CURRENT=$(brightnessctl -d "$DEVICE" get 2>/dev/null)
if [ "${CURRENT:-0}" -gt 0 ]; then
    brightnessctl -d "$DEVICE" set 0 > /dev/null
    notify-send -a "Quick Settings" "󰥻  KB Light" "Off" -t 1500
else
    brightnessctl -d "$DEVICE" set 100% > /dev/null
    notify-send -a "Quick Settings" "󰥻  KB Light" "On" -t 1500
fi
