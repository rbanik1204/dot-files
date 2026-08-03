#!/bin/bash
if command -v wpctl > /dev/null; then
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
else
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
fi

if command -v wpctl > /dev/null && wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "MUTED"; then
    notify-send -a "Quick Settings" "󰍭  Mic" "Muted" -t 1500
else
    notify-send -a "Quick Settings" "󰍬  Mic" "Unmuted" -t 1500
fi
