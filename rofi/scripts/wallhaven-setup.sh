#!/usr/bin/env bash
#
# wallhaven-setup.sh
# Stores your Wallhaven API key locally (never echoed, never in this repo).
# Run once:  ~/.config/rofi/scripts/wallhaven-setup.sh
#
# Get your key from: https://wallhaven.cc/settings/account (API Key section)
# NOTE: NSFW results only come back if your Wallhaven account itself has
# "Browsing -> NSFW" enabled in account settings; the API key alone isn't
# enough.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_FILE="$SCRIPT_DIR/.wallhaven_api_key"
LIST_THEME="$SCRIPT_DIR/../colors/wallpaper-picker-list.rasi"

key=$(rofi -dmenu -password -p "eoaWc2RGbwowx7n4dFvQI9owXIeY3i6R" -theme "$LIST_THEME" 2>/dev/null || true)
[ -z "${key:-}" ] && exit 0

printf "%s" "$key" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

notify-send -a "Wallpaper Picker" "Wallhaven API key saved" "Stored at ~/.config/rofi/scripts/.wallhaven_api_key" 2>/dev/null || true
