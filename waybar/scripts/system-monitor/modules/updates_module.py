#!/usr/bin/env python3
"""
modules/updates_module.py — Waybar custom module for pending Arch updates.
Hides itself (empty text) at 0 updates if you set "min-count":1 in config;
otherwise shows "0" — see config-snippet.jsonc for both options.
"""

import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib.utils import load_cache  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"
ICON = "󰚰"


def main():
    cache = load_cache(CACHE_PATH)
    data = cache.get("updates", {})

    if not data.get("available"):
        print(json.dumps({"text": f"{ICON} N/A", "tooltip": "checkupdates not available", "class": "disabled"}))
        return

    count = data.get("count") or 0
    packages = data.get("packages", [])

    text = f"{ICON} {count}"
    css_class = "has-updates" if count > 0 else "up-to-date"

    if packages:
        shown = packages[:20]
        extra = f"\n… and {len(packages) - 20} more" if len(packages) > 20 else ""
        tooltip = f"<b>{count} update(s) available</b>\n" + "\n".join(shown) + extra
    else:
        tooltip = "System is up to date"

    print(json.dumps({"text": text, "tooltip": tooltip, "class": css_class}))


if __name__ == "__main__":
    main()
