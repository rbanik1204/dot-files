"""
collectors/cpu.py

CPU usage, per-core frequency, temperature (k10temp) and package power
(zenpower/k10temp if present) for a Ryzen 7000 series CPU.

Uses psutil where possible (fast, no subprocess spawn). Falls back to
`sensors -j` (lm_sensors, JSON output) for temperature/power, since psutil
doesn't reliably expose AMD package power.
"""

import json
import os

import psutil

from lib.utils import run, to_float, which

_SENSOR_CHIP_CANDIDATES = ("k10temp", "zenpower")


def _sensors_json() -> dict:
    if not which("sensors"):
        return {}
    out = run(["sensors", "-j"], timeout=1.5)
    if not out:
        return {}
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return {}


def _extract_cpu_temp_power(sensors_data: dict) -> tuple[float | None, float | None]:
    temp_c = None
    power_w = None
    for chip_name, readings in sensors_data.items():
        if not any(chip_name.startswith(c) for c in _SENSOR_CHIP_CANDIDATES):
            continue
        for label, values in readings.items():
            if not isinstance(values, dict):
                continue
            for key, val in values.items():
                if key.startswith("temp") and key.endswith("_input") and temp_c is None:
                    temp_c = to_float(val)
                if key.startswith("power") and key.endswith("_input") and power_w is None:
                    power_w = to_float(val)
    return temp_c, power_w


def collect() -> dict:
    usage_pct = psutil.cpu_percent(interval=None)
    per_core = psutil.cpu_percent(interval=None, percpu=True)

    freqs = psutil.cpu_freq(percpu=True) or []
    per_core_freq = [round(f.current) for f in freqs] if freqs else []
    avg_freq = round(sum(per_core_freq) / len(per_core_freq)) if per_core_freq else None

    try:
        load1, load5, load15 = os.getloadavg()
    except OSError:
        load1 = load5 = load15 = None

    sensors_data = _sensors_json()
    temp_c, power_w = _extract_cpu_temp_power(sensors_data)

    return {
        "usage_pct": round(usage_pct, 1),
        "per_core_pct": per_core,
        "temp_c": round(temp_c, 1) if temp_c is not None else None,
        "avg_freq_mhz": avg_freq,
        "per_core_freq_mhz": per_core_freq,
        "package_power_w": round(power_w, 1) if power_w is not None else None,
        "load_avg": {
            "1m": round(load1, 2) if load1 is not None else None,
            "5m": round(load5, 2) if load5 is not None else None,
            "15m": round(load15, 2) if load15 is not None else None,
        },
    }
