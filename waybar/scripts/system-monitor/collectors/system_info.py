"""
collectors/system_info.py

Slow-changing system facts: kernel, uptime, hostname, Hyprland version,
Waybar version. Polled infrequently by monitor.py since none of this
changes on a per-second basis.
"""

import platform
import socket
import time

from lib.utils import run, which


def _uptime_str() -> str | None:
    try:
        with open("/proc/uptime") as f:
            seconds = float(f.readline().split()[0])
    except (FileNotFoundError, ValueError, IndexError):
        return None
    days, rem = divmod(int(seconds), 86400)
    hours, rem = divmod(rem, 3600)
    minutes = rem // 60
    parts = []
    if days:
        parts.append(f"{days}d")
    if hours or days:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")
    return " ".join(parts)


def _hyprland_version() -> str | None:
    if not which("hyprctl"):
        return None
    out = run(["hyprctl", "version"], timeout=1.5)
    if not out:
        return None
    first_line = out.splitlines()[0] if out.splitlines() else out
    return first_line.strip()


def _waybar_version() -> str | None:
    if not which("waybar"):
        return None
    out = run(["waybar", "--version"], timeout=1.5)
    return out.strip() if out else None


def collect() -> dict:
    return {
        "kernel": platform.release(),
        "hostname": socket.gethostname(),
        "uptime": _uptime_str(),
        "hyprland_version": _hyprland_version(),
        "waybar_version": _waybar_version(),
    }
