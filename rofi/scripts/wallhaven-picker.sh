#!/usr/bin/env bash
#
# wallhaven-picker.sh (v2 - dynamic search)
# Bind this to a key in hyprland.conf, e.g.:
#   bind = $mainMod, W, exec, ~/.config/rofi/scripts/wallhaven-picker.sh
#
# Flow:
#   1. Category: SFW / NSFW (compact list theme)
#   2. If NSFW -> pin prompt
#   3. Hands off to wallhaven-modi.sh via rofi script mode: type a query,
#      press Enter, grid refreshes live in the same window. Type a new
#      query any time to re-search without leaving the grid.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_THEME="$SCRIPT_DIR/../colors/wallpaper-picker-list.rasi"
GRID_THEME="$SCRIPT_DIR/../colors/wallpaper-picker-grid.rasi"
API_KEY_FILE="$SCRIPT_DIR/.wallhaven_api_key"
PIN_FILE="$SCRIPT_DIR/.nsfw_pin"
CACHE_DIR="$HOME/.cache/wallhaven_picker"
PURITY_FILE="$CACHE_DIR/.purity"

mkdir -p "$CACHE_DIR"

notify() { command -v notify-send >/dev/null && notify-send -a "Wallpaper Picker" "$1" "$2" || true; }

# ---------- API key check ----------
if [ ! -f "$API_KEY_FILE" ]; then
    notify "Wallhaven API key missing" "Opening setup..."
    "$SCRIPT_DIR/wallhaven-setup.sh"
    [ ! -f "$API_KEY_FILE" ] && exit 1
fi

# ---------- Step 1: category ----------
category=$(printf "%s\n%s\n" "  SFW" "  NSFW" | rofi -dmenu -i -p "Category" -theme "$LIST_THEME")
[ -z "${category:-}" ] && exit 0

if [[ "$category" == *"NSFW"* ]]; then
    purity="001"

    if [ ! -f "$PIN_FILE" ]; then
        notify "NSFW pin not set" "Run nsfw-lock-setup.sh once to create a pin."
        "$SCRIPT_DIR/nsfw-lock-setup.sh"
    fi

    stored_hash=$(cat "$PIN_FILE" 2>/dev/null || echo "")
    ok=0
    for attempt in 1 2 3; do
        pin=$(rofi -dmenu -password -p "NSFW Pin" -theme "$LIST_THEME")
        [ -z "${pin:-}" ] && exit 0
        entered_hash=$(printf "%s" "$pin" | sha256sum | awk '{print $1}')
        if [ "$entered_hash" == "$stored_hash" ]; then
            ok=1
            break
        fi
        notify "Wrong pin" "Attempt $attempt/3"
    done
    [ "$ok" -ne 1 ] && { notify "Locked out" "Too many wrong attempts."; exit 1; }
else
    purity="100"
fi

# stash purity for wallhaven-modi.sh to read (it has no other way to know
# which category you picked, since rofi script mode only passes the query text)
echo "$purity" > "$PURITY_FILE"

# ---------- Step 2: live search + grid, all in one rofi window ----------
rofi -show wallhaven -modi "wallhaven:$SCRIPT_DIR/wallhaven-modi.sh" -theme "$GRID_THEME"