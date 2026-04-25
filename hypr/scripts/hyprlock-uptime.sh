#!/bin/bash
# hyprlock-uptime.sh
echo "  $(uptime -p | sed 's/up //')"