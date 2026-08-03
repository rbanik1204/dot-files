#!/bin/bash
# Requires brightnessctl
DEVICE=$(brightnessctl -l 2>/dev/null | grep -i "kbd_backlight" | grep -oP "'\K[^']+" | head -n1)
if [ -z "$DEVICE" ]; then
    echo "false"
    exit 0
fi
CURRENT=$(brightnessctl -d "$DEVICE" get 2>/dev/null)
if [ "${CURRENT:-0}" -gt 0 ]; then
    echo "true"
else
    echo "false"
fi
