#!/usr/bin/env python3
"""
modules/vpn_module.py — Waybar custom module for VPN status.

Waybar's "custom" modules don't support conditional visibility directly,
so "only visible when connected" is implemented by printing NOTHING
(empty stdout) when no VPN is active. An empty "text" collapses the module
to zero width in waybar, which is the standard trick for optional modules.
"""

import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib.utils import load_cache  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"
ICON = "󰖂"


def main():
    cache = load_cache(CACHE_PATH)
    net = cache.get("network", {})

    if not net.get("vpn_active"):
        # Print nothing -> waybar collapses the module (module stays hidden).
        return

    print(
        json.dumps(
            {
                "text": f"{ICON} VPN",
                "tooltip": "VPN connection active",
                "class": "connected",
            }
        )
    )


if __name__ == "__main__":
    main()
