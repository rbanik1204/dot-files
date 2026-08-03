PARTITIONS=(
    "/|root"
    "/workspace|workspace"
)

STATE_FILE="/tmp/waybar_disk_index"
ACTIVE_PATH_FILE="/tmp/waybar_disk_active_path"

INDEX=0
[ -f "$STATE_FILE" ] && INDEX=$(cat "$STATE_FILE")

if [ "$1" = "click" ]; then
    INDEX=$(( (INDEX + 1) % ${#PARTITIONS[@]} ))
    echo $INDEX > "$STATE_FILE"
fi

ENTRY="${PARTITIONS[$INDEX]}"
PATH_="${ENTRY%%|*}"
LABEL="${ENTRY##*|}"

# Write active path so other apps can read it
echo "$PATH_" > "$ACTIVE_PATH_FILE"

READ=$(df -h "$PATH_" | awk 'NR==2 {print $3"/"$2" ("$5")"}')

echo "{\"text\": \"󰋊 $LABEL: $READ\", \"tooltip\": \"$PATH_ → $READ\"}"