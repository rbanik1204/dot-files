#!/usr/bin/env bash
# install.sh — installs the system-monitor daemon + waybar modules alongside
# your existing waybar config. Does NOT touch config.jsonc, style.css,
# colors.css, or any existing scripts/ — you wire modules in manually using
# config/config-snippet.jsonc and config/style-snippet.css (see README.md).

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAYBAR_DIR="${HOME}/.config/waybar"
DEST="${WAYBAR_DIR}/scripts/system-monitor"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

echo "==> Checking for python dependency: psutil"
if ! python3 -c "import psutil" 2>/dev/null; then
  echo "    psutil not found. Install with: sudo pacman -S python-psutil"
  echo "    (continuing install anyway — monitor.py will error until it's installed)"
fi

echo "==> Installing daemon + modules to ${DEST}"
mkdir -p "${DEST}"
cp -r "${SRC_DIR}/scripts/system-monitor/." "${DEST}/"
chmod +x "${DEST}/monitor.py"
chmod +x "${DEST}/modules/"*.py
chmod +x "${DEST}/scripts_helpers/"*.sh

echo "==> Installing systemd user service"
mkdir -p "${SYSTEMD_USER_DIR}"
cp "${SRC_DIR}/systemd/waybar-monitor.service" "${SYSTEMD_USER_DIR}/"
systemctl --user daemon-reload
systemctl --user enable --now waybar-monitor.service

echo ""
echo "==> Done."
echo ""
echo "Next steps (manual, by design — this script never edits your existing config):"
echo "  1. Merge module blocks from:"
echo "       ${SRC_DIR}/config/config-snippet.jsonc"
echo "     into your ${WAYBAR_DIR}/config.jsonc (or config-bottom.jsonc)."
echo "  2. Append new classes from:"
echo "       ${SRC_DIR}/config/style-snippet.css"
echo "     to your ${WAYBAR_DIR}/style.css (or style-bottom.css)."
echo "  3. Reload waybar (e.g. 'killall waybar; ~/.config/waybar/scripts/launch.sh')."
echo ""
echo "Check daemon status any time with:"
echo "  systemctl --user status waybar-monitor.service"
echo "  cat /tmp/waybar-monitor.json | jq ."
systemctl --user restart waybar-monitor.service
sleep 3
cat /tmp/waybar-monitor.json | python3 -c "import json,sys; print(json.load(sys.stdin)['updates'])"  