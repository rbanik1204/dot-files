#!/bin/bash
# Requires wireplumber (wpctl). Falls back to pactl if unavailable.
if command -v wpctl > /dev/null; then
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "MUTED"; then
        echo "false"
    else
        echo "true"
    fi
else
    if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q "yes"; then
        echo "false"
    else
        echo "true"
    fi
fi
