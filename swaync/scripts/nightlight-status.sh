#!/bin/bash
# Requires hyprsunset. Swap to gammastep/wlsunset below if you use those instead.
if pgrep -x hyprsunset > /dev/null; then
    echo "true"
else
    echo "false"
fi
