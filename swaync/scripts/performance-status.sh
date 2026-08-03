#!/bin/bash
# Requires power-profiles-daemon (powerprofilesctl)
if [ "$(powerprofilesctl get 2>/dev/null)" = "performance" ]; then
    echo "true"
else
    echo "false"
fi
