#!/usr/bin/env python3
"""
modules/fan_module.py — Waybar custom module for fan RPM(s).
Shows the fastest fan in the bar text; all fans listed in the tooltip.
"""

import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib.utils import load_cache  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"
ICON = "󰈐"


def main():
    cache = load_cache(CACHE_PATH)
    data = cache.get("fans", {})
    fans = data.get("fans", [])

    if not data.get("available") or not fans:
        print(json.dumps({"text": f"{ICON} N/A", "tooltip": "No fan sensors detected", "class": "disabled"}))
        return

    fastest = max(fans, key=lambda f: f["rpm"])
    text = f"{ICON} {fastest['rpm']} RPM"

    tooltip_lines = [f"<b>Fans</b>"] + [f"{f['label']} ({f['source']}): {f['rpm']} RPM" for f in fans]
    tooltip = "\n".join(tooltip_lines)

    print(json.dumps({"text": text, "tooltip": tooltip, "class": "normal"}))


if __name__ == "__main__":
    main()
