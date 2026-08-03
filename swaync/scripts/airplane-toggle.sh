#!/bin/bash
if rfkill list 2>/dev/null | grep -q "Soft blocked: yes"; then
    rfkill unblock all
    notify-send -a "Quick Settings" "󰀝  Airplane Mode" "Off" -t 1500
else
    rfkill block all
    notify-send -a "Quick Settings" "󰀝  Airplane Mode" "On" -t 1500
fi
