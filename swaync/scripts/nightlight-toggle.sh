#!/bin/bash
# Requires hyprsunset (pacman -S hyprsunset). Change the binary/args here if you
# use gammastep or wlsunset instead, e.g.:
#   gammastep -O 4500 &   /   wlsunset -t 4000
if pgrep -x hyprsunset > /dev/null; then
    pkill hyprsunset
    notify-send -a "Quick Settings" "󰛨  Night Light" "Off" -t 1500
else
    hyprsunset -t 4500 & disown
    notify-send -a "Quick Settings" "󰛨  Night Light" "On" -t 1500
fi
