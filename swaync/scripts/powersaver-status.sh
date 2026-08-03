#!/bin/bash
if [ "$(powerprofilesctl get 2>/dev/null)" = "power-saver" ]; then
    echo "true"
else
    echo "false"
fi
