#!/bin/bash
# Echo true/false for SwayNC toggle state
if nmcli radio wifi 2>/dev/null | grep -q "enabled"; then
    echo "true"
else
    echo "false"
fi
