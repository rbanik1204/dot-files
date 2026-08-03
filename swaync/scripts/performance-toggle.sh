#!/bin/bash
if [ "$(powerprofilesctl get 2>/dev/null)" = "performance" ]; then
    powerprofilesctl set balanced
    notify-send -a "Quick Settings" "󰾆  Performance Mode" "Off (Balanced)" -t 1500
else
    powerprofilesctl set performance
    notify-send -a "Quick Settings" "󰓅  Performance Mode" "On" -t 1500
fi
