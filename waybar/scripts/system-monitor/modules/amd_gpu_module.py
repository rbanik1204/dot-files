#!/usr/bin/env python3
"""
modules/amd_gpu_module.py — Waybar custom module output for the AMD iGPU.
Reads the shared cache only.
"""

import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib.utils import load_cache  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"
ICON = "󰍛"


def main():
    cache = load_cache(CACHE_PATH)
    gpu = cache.get("amd_gpu", {})

    if not gpu.get("available"):
        print(json.dumps({"text": f"{ICON} N/A", "tooltip": "AMD GPU unavailable", "class": "disabled"}))
        return

    temp = gpu.get("temp_c")
    text = f"{ICON} {temp if temp is not None else '--'}°C"

    css_class = "normal"
    if temp is not None and temp >= 90:
        css_class = "critical"
    elif temp is not None and temp >= 80:
        css_class = "warning"

    tooltip = (
        f"<b>AMD Radeon iGPU</b>\n"
        f"Temp: {temp}°C\n"
        f"Power: {gpu.get('power_w')} W\n"
        f"Clock: {gpu.get('clock_mhz')} MHz\n"
        f"Voltage: {gpu.get('voltage_v')} V\n"
        f"Usage: {gpu.get('usage_pct')}%\n"
        f"Status: {gpu.get('renderer')}"
    )

    print(json.dumps({"text": text, "tooltip": tooltip, "class": css_class}))


if __name__ == "__main__":
    main()
