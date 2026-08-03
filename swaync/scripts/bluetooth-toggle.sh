#!/bin/bash
if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    bluetoothctl power off > /dev/null
    notify-send -a "Quick Settings" "󰂲  Bluetooth" "Turned off" -t 1500
else
    bluetoothctl power on > /dev/null
    notify-send -a "Quick Settings" "󰂯  Bluetooth" "Turned on" -t 1500
fi
