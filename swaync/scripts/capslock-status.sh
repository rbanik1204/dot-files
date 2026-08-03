#!/bin/bash
LED=$(ls /sys/class/leds/ 2>/dev/null | grep -i "capslock" | head -n1)
if [ -n "$LED" ] && [ "$(cat "/sys/class/leds/$LED/brightness" 2>/dev/null)" -gt 0 ] 2>/dev/null; then
    echo "true"
else
    echo "false"
fi
