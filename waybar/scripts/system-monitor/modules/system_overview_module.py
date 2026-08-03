#!/usr/bin/env python3
"""
modules/system_overview_module.py — Waybar "System" module.

Display mode (no args): small bar icon + one-line tooltip summary.
Click mode ("show"): builds a full system overview and presents it via
notify-send (default) or fuzzel (if NOTIFY_BACKEND=fuzzel), similar to
Quickshell's system overview popup.
"""

import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib.utils import load_cache, which  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"
ICON = "󰍹"

# "notify-send" (default, needs a notification daemon like dunst/mako/swaync)
# or "fuzzel" (renders as a dmenu-style popup instead of a notification).
NOTIFY_BACKEND = os.environ.get("WAYBAR_SYSOVERVIEW_BACKEND", "notify-send")


def _overview_text(cache: dict) -> str:
    cpu = cache.get("cpu", {})
    nv = cache.get("nvidia", {})
    amd = cache.get("amd_gpu", {})
    ram_line = _ram_line()
    batt = cache.get("battery", {})
    fans = cache.get("fans", {}).get("fans", [])
    profile = cache.get("power_profile", {})
    sysinfo = cache.get("system", {})
    net = cache.get("network", {})

    lines = []
    lines.append(f"<b>CPU</b>  {cpu.get('usage_pct', '--')}%  |  {cpu.get('temp_c', '--')}°C  |  {cpu.get('avg_freq_mhz', '--')} MHz")

    if nv.get("available"):
        lines.append(f"<b>NVIDIA GPU</b>  {nv.get('usage_pct', '--')}%  |  {nv.get('temp_c', '--')}°C  |  VRAM {nv.get('vram_pct', '--')}%")
    if amd.get("available"):
        lines.append(f"<b>AMD iGPU</b>  {amd.get('temp_c', '--')}°C  |  {amd.get('power_w', '--')} W")

    lines.append(ram_line)

    if batt.get("available"):
        lines.append(
            f"<b>Battery</b>  {batt.get('percent', '--')}%  ({batt.get('status', '--')})  |  Health {batt.get('health_pct', '--')}%"
        )

    if fans:
        fan_str = ", ".join(f"{f['rpm']} RPM" for f in fans)
        lines.append(f"<b>Fans</b>  {fan_str}")

    if profile.get("available"):
        lines.append(f"<b>Power Profile</b>  {profile.get('current', '--')}")

    lines.append(f"<b>Kernel</b>  {sysinfo.get('kernel', '--')}  |  Up {sysinfo.get('uptime', '--')}")
    lines.append(_disk_line())

    if net.get("available"):
        lines.append(
            f"<b>Network</b>  {net.get('interface', '--')}  |  ↓{net.get('download_kbps', '--')} KB/s ↑{net.get('upload_kbps', '--')} KB/s"
        )

    return "\n".join(lines)


def _ram_line() -> str:
    try:
        import psutil

        vm = psutil.virtual_memory()
        return f"<b>RAM</b>  {vm.percent}%  ({vm.used // (1024**2)} / {vm.total // (1024**2)} MB)"
    except Exception:
        return "<b>RAM</b>  --"


def _disk_line() -> str:
    try:
        import psutil

        du = psutil.disk_usage("/")
        return f"<b>Disk (/)</b>  {du.percent}%  ({du.used // (1024**3)} / {du.total // (1024**3)} GB)"
    except Exception:
        return "<b>Disk</b>  --"


def show():
    cache = load_cache(CACHE_PATH)
    body = _overview_text(cache)

    if NOTIFY_BACKEND == "fuzzel" and which("fuzzel"):
        # fuzzel is a dmenu-style launcher; feed it lines via stdin as a
        # read-only "menu" (selecting an entry just closes the popup).
        plain = body.replace("<b>", "").replace("</b>", "")
        subprocess.run(
            ["fuzzel", "--dmenu", "--prompt", "System Overview "],
            input=plain,
            text=True,
        )
    elif which("notify-send"):
        subprocess.run(
            [
                "notify-send",
                "-a",
                "waybar",
                "-i",
                "utilities-system-monitor",
                "System Overview",
                body,
            ]
        )
    else:
        # Last-resort fallback: print to stderr so at least `journalctl`/logs show it.
        print(body.replace("<b>", "").replace("</b>", ""), file=sys.stderr)


def render():
    cache = load_cache(CACHE_PATH)
    cpu = cache.get("cpu", {})
    text = f"{ICON} {cpu.get('usage_pct', '--')}%"
    print(json.dumps({"text": text, "tooltip": "Click for full system overview", "class": "normal"}))


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "show":
        show()
    else:
        render()
