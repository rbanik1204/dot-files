#!/bin/bash
# Tracks state in a cache file since Hyprland has no direct "is touchpad enabled" query.
STATE_FILE="$HOME/.cache/swaync-touchpad-state"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "disabled" ]; then
    echo "false"
else
    echo "true"
fi
