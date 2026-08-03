#!/bin/bash
# Requires cliphist + wl-clipboard + wofi (swap wofi for rofi -dmenu if preferred)
cliphist list | wofi --dmenu -p "Clipboard History" | cliphist decode | wl-copy
