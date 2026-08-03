"""
collectors/fans.py

Reads all fan RPM sensors exposed via lm_sensors (`sensors -j`).
Works generically for whatever fan-capable chip is present (nct6775,
it87, amdgpu hwmon fan1_input, etc) rather than hardcoding chip names.
"""

import json

from lib.utils import run, to_int, which


def collect() -> dict:
    if not which("sensors"):
        return {"available": False, "fans": []}

    out = run(["sensors", "-j"], timeout=1.5)
    if not out:
        return {"available": False, "fans": []}

    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return {"available": False, "fans": []}

    fans = []
    for chip_name, readings in data.items():
        if not isinstance(readings, dict):
            continue
        for label, values in readings.items():
            if not isinstance(values, dict):
                continue
            if not label.lower().startswith("fan"):
                continue
            for key, val in values.items():
                if key.endswith("_input"):
                    rpm = to_int(val)
                    if rpm is not None:
                        fans.append({"source": chip_name, "label": label, "rpm": rpm})

    return {"available": len(fans) > 0, "fans": fans}
