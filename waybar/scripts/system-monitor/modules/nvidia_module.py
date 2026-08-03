#!/usr/bin/env python3
"""
modules/nvidia_module.py — Waybar custom module output for the NVIDIA GPU.

Reads ONLY the shared cache written by monitor.py (no subprocess calls),
so it is safe to poll every second from waybar without any real cost.

Output: single-line JSON matching waybar's custom module schema
{"text": ..., "tooltip": ..., "class": ..., "percentage": ...}
"""

import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib.utils import load_cache  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"
ICON = ""


def main():
    cache = load_cache(CACHE_PATH)
    gpu = cache.get("nvidia", {})

    if not gpu.get("available"):
        print(json.dumps({"text": f"{ICON} N/A", "tooltip": "NVIDIA GPU unavailable", "class": "disabled"}))
        return

    usage = gpu.get("usage_pct")
    temp = gpu.get("temp_c")

    text = f"{ICON} {usage if usage is not None else '--'}%"

    css_class = "normal"
    if temp is not None and temp >= 80:
        css_class = "critical"
    elif temp is not None and temp >= 70:
        css_class = "warning"

    procs = gpu.get("processes", [])
    proc_lines = "\n".join(f"  {p['name']} ({p['vram_mb']} MB)" for p in procs) or "  none"

    tooltip = (
        f"<b>NVIDIA GPU</b>\n"
        f"Temp: {temp}°C\n"
        f"VRAM: {gpu.get('vram_used_mb')}/{gpu.get('vram_total_mb')} MB ({gpu.get('vram_pct')}%)\n"
        f"Power: {gpu.get('power_draw_w')}/{gpu.get('power_limit_w')} W\n"
        f"Clock: {gpu.get('clock_sm_mhz')} MHz (mem {gpu.get('clock_mem_mhz')} MHz)\n"
        f"Fan: {gpu.get('fan_pct')}%\n"
        f"P-State: {gpu.get('pstate')}\n"
        f"Driver: {gpu.get('driver_version')}\n"
        f"Processes:\n{proc_lines}"
    )

    print(
        json.dumps(
            {
                "text": text,
                "tooltip": tooltip,
                "class": css_class,
                "percentage": usage if usage is not None else 0,
            }
        )
    )


if __name__ == "__main__":
    main()
