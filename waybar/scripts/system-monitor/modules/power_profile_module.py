#!/usr/bin/env python3
"""
modules/power_profile_module.py — Waybar custom module for the power profile.

Two modes:
  (no args)   -> display mode, reads the cache only (cheap, safe to poll)
  cycle       -> click action: cycles balanced -> performance -> power-saver
                 by calling powerprofilesctl directly (a click should act
                 immediately, not wait for the next daemon tick)

waybar config wires these together via "exec" (display) and "on-click"
(cycle), see config/config-snippet.jsonc.
"""

import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib.utils import load_cache  # noqa: E402
from collectors import power_profile  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"

ICONS = {
    "performance": "󰓅",
    "balanced": "⚡",
    "power-saver": "󰾆",
}


def render():
    cache = load_cache(CACHE_PATH)
    profile = cache.get("power_profile", {})
    current = profile.get("current")

    if not profile.get("available") or not current:
        print(json.dumps({"text": "⚡ N/A", "tooltip": "power-profiles-daemon unavailable", "class": "disabled"}))
        return

    icon = ICONS.get(current, "⚡")
    text = f"{icon} {current.replace('-', ' ').title()}"
    tooltip = f"<b>Power Profile</b>\nCurrent: {current}\nClick to cycle: balanced → performance → power-saver"

    print(json.dumps({"text": text, "tooltip": tooltip, "class": current}))


def cycle():
    new_profile = power_profile.toggle()
    # No stdout needed for a click action; waybar's next poll (exec) will
    # pick up the change either from our own next daemon tick or immediately
    # if the profile changed successfully.
    if new_profile is None:
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "cycle":
        cycle()
    else:
        render()
