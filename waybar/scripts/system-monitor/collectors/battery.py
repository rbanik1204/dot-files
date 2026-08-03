"""
collectors/battery.py

Battery health, cycle count, voltage, charge rate and remaining time.
psutil gives percent/plugged/secsleft; the rest comes straight from
/sys/class/power_supply/BAT*/ since psutil doesn't expose it.
"""

import glob
import os

import psutil

from lib.utils import read_sysfs, to_float, to_int


def _find_battery_path() -> str | None:
    for path in glob.glob("/sys/class/power_supply/BAT*"):
        if os.path.isdir(path):
            return path
    return None


def collect() -> dict:
    battery_path = _find_battery_path()
    psutil_batt = psutil.sensors_battery()

    if not battery_path and not psutil_batt:
        return {"available": False}

    result = {"available": True}

    if psutil_batt:
        result["percent"] = round(psutil_batt.percent, 1)
        result["plugged_in"] = psutil_batt.power_plugged
        secs = psutil_batt.secsleft
        if isinstance(secs, (int, float)) and secs > 0:
            hrs, rem = divmod(int(secs), 3600)
            mins = rem // 60
            result["time_remaining"] = f"{hrs}h {mins}m"
        else:
            result["time_remaining"] = None

    if battery_path:
        charge_full = to_float(read_sysfs(os.path.join(battery_path, "charge_full")))
        charge_full_design = to_float(
            read_sysfs(os.path.join(battery_path, "charge_full_design"))
        )
        energy_full = to_float(read_sysfs(os.path.join(battery_path, "energy_full")))
        energy_full_design = to_float(
            read_sysfs(os.path.join(battery_path, "energy_full_design"))
        )

        health_pct = None
        if charge_full and charge_full_design:
            health_pct = round(charge_full / charge_full_design * 100, 1)
        elif energy_full and energy_full_design:
            health_pct = round(energy_full / energy_full_design * 100, 1)

        cycle_count = to_int(read_sysfs(os.path.join(battery_path, "cycle_count")))
        voltage_uv = to_float(read_sysfs(os.path.join(battery_path, "voltage_now")))
        current_ua = to_float(read_sysfs(os.path.join(battery_path, "current_now")))
        power_uw = to_float(read_sysfs(os.path.join(battery_path, "power_now")))
        status = read_sysfs(os.path.join(battery_path, "status"))

        charge_rate_w = None
        if power_uw is not None:
            charge_rate_w = round(power_uw / 1_000_000, 2)
        elif voltage_uv is not None and current_ua is not None:
            charge_rate_w = round((voltage_uv / 1_000_000) * (current_ua / 1_000_000), 2)

        result.update(
            {
                "health_pct": health_pct,
                "cycle_count": cycle_count,
                "voltage_v": round(voltage_uv / 1_000_000, 3) if voltage_uv else None,
                "charge_rate_w": charge_rate_w,
                "status": status,
            }
        )

    return result
