#!/bin/bash

PARTITIONS=(
    "/|root"
    "/workspace|workspace"
)

STATE_FILE="/tmp/waybar_disk_index"

# Read current index
INDEX=0
[ -f "$STATE_FILE" ] && INDEX=$(cat "$STATE_FILE")

# On click, advance index
if [ "$1" = "click" ]; then
    INDEX=$(( (INDEX + 1) % ${#PARTITIONS[@]} ))
    echo $INDEX > "$STATE_FILE"
fi

# Get current partition info
ENTRY="${PARTITIONS[$INDEX]}"
PATH_="${ENTRY%%|*}"
LABEL="${ENTRY##*|}"

# Get disk usage
READ=$(df -h "$PATH_" | awk 'NR==2 {print $3"/"$2" ("$5")"}')

echo "{\"text\": \"󰋊 $LABEL: $READ\", \"tooltip\": \"$PATH_ → $READ\"}"