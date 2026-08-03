"""
collectors/amd_gpu.py

Collects stats for the integrated AMD Radeon 740M/760M via sysfs.
No external tools required (no `sensors` dependency for this one), which
keeps it fast and reliable across kernel versions.

We locate the amdgpu DRM card by scanning /sys/class/drm/card*/device/driver
for a symlink pointing at the "amdgpu" driver, then read its hwmon node.
"""

import glob
import os

from lib.utils import read_sysfs, read_sysfs_float, run, which


def _find_amdgpu_card() -> str | None:
    for card_path in glob.glob("/sys/class/drm/card*/device"):
        driver_link = os.path.join(card_path, "driver")
        try:
            target = os.readlink(driver_link)
        except OSError:
            continue
        if target.endswith("amdgpu"):
            return card_path
    return None


def _find_hwmon(device_path: str) -> str | None:
    hwmon_glob = os.path.join(device_path, "hwmon", "hwmon*")
    matches = glob.glob(hwmon_glob)
    return matches[0] if matches else None


def _current_renderer() -> str | None:
    """
    Best-effort detection of which GPU is currently rendering the active
    Hyprland session, using DRI_PRIME / __GLX_VENDOR env is not queryable
    system-wide, so instead we report which card has non-zero GPU busy%
    as a proxy signal. Falls back to None if unavailable.
    """
    card = _find_amdgpu_card()
    if not card:
        return None
    busy = read_sysfs(os.path.join(card, "gpu_busy_percent"))
    if busy is None:
        return None
    try:
        return "AMD (active)" if int(busy) > 5 else "Idle"
    except ValueError:
        return None


def collect() -> dict:
    card = _find_amdgpu_card()
    if not card:
        return {"available": False}

    hwmon = _find_hwmon(card)
    if not hwmon:
        return {"available": False}

    temp_raw = read_sysfs_float(os.path.join(hwmon, "temp1_input"), scale=1000.0)
    power_raw = read_sysfs_float(os.path.join(hwmon, "power1_average"), scale=1_000_000.0)
    voltage_raw = read_sysfs_float(os.path.join(hwmon, "in0_input"), scale=1000.0)

    # sclk (core clock) comes from pp_dpm_sclk, format like:
    #   0: 200Mhz
    #   1: 1900Mhz *
    sclk_mhz = None
    pp_dpm_sclk = read_sysfs(os.path.join(card, "pp_dpm_sclk"))
    if pp_dpm_sclk:
        for line in pp_dpm_sclk.splitlines():
            if "*" in line:
                digits = "".join(ch for ch in line.split(":")[1] if ch.isdigit())
                if digits:
                    sclk_mhz = int(digits)
                break

    busy_pct = read_sysfs(os.path.join(card, "gpu_busy_percent"))

    return {
        "available": True,
        "usage_pct": int(busy_pct) if busy_pct and busy_pct.isdigit() else None,
        "temp_c": round(temp_raw, 1) if temp_raw is not None else None,
        "power_w": round(power_raw, 1) if power_raw is not None else None,
        "voltage_v": round(voltage_raw, 3) if voltage_raw is not None else None,
        "clock_mhz": sclk_mhz,
        "renderer": _current_renderer(),
        "igpu_active": (busy_pct is not None and busy_pct.isdigit() and int(busy_pct) > 5),
    }
