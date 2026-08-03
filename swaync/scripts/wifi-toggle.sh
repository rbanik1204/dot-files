#!/bin/bash
# Flip WiFi radio on/off via NetworkManager
if nmcli radio wifi 2>/dev/null | grep -q "enabled"; then
    nmcli radio wifi off
    notify-send -a "Quick Settings" "󰤭  WiFi" "Turned off" -t 1500
else
    nmcli radio wifi on
    notify-send -a "Quick Settings" "󰤨  WiFi" "Turned on" -t 1500
fi
