#!/bin/bash
# Airplane mode is "on" (active) when radios are soft-blocked via rfkill
if rfkill list 2>/dev/null | grep -q "Soft blocked: yes"; then
    echo "true"
else
    echo "false"
fi
