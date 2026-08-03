#!/usr/bin/env bash
# Optional on-click helper for custom/updates.
# Opens your terminal running an AUR helper so you can review/apply updates.
# Edit TERMINAL and UPDATE_CMD to match your setup, or delete the "on-click"
# line in config-snippet.jsonc if you don't want this behaviour at all.

TERMINAL="${TERMINAL:-kitty}"
UPDATE_CMD="yay"   # or: yay

exec "$TERMINAL" -e "$UPDATE_CMD"
