#!/bin/bash
mkdir -p "$HOME/Videos"
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT wf-recorder
    notify-send -a "Quick Settings" "󰑋  Screen Recording" "Stopped" -t 1500
else
    wf-recorder -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4" > /dev/null 2>&1 & disown
    notify-send -a "Quick Settings" "󰑋  Screen Recording" "Started" -t 1500
fi
