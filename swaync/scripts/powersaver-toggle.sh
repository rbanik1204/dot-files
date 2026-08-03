#!/bin/bash
if [ "$(powerprofilesctl get 2>/dev/null)" = "power-saver" ]; then
    powerprofilesctl set balanced
    notify-send -a "Quick Settings" "󰾆  Power Saver" "Off (Balanced)" -t 1500
else
    powerprofilesctl set power-saver
    notify-send -a "Quick Settings" "󰾆  Power Saver" "On" -t 1500
fi
