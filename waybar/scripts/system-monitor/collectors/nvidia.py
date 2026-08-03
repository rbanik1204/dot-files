"""
collectors/nvidia.py

Collects RTX 3050 (or any NVIDIA GPU) stats via a single nvidia-smi call
(one CSV query = one process spawn, instead of separate calls per metric).
"""

from lib.utils import run, to_float, to_int, which

_QUERY_FIELDS = [
    "utilization.gpu",
    "temperature.gpu",
    "memory.used",
    "memory.total",
    "clocks.sm",
    "clocks.mem",
    "power.draw",
    "power.limit",
    "fan.speed",
    "pstate",
    "driver_version",
]


def _collect_processes() -> list[dict]:
    out = run(
        [
            "nvidia-smi",
            "--query-compute-apps=pid,process_name,used_memory",
            "--format=csv,noheader,nounits",
        ]
    )
    if not out:
        return []
    processes = []
    for line in out.splitlines():
        parts = [p.strip() for p in line.split(",")]
        if len(parts) != 3:
            continue
        processes.append(
            {
                "pid": to_int(parts[0]),
                "name": parts[1],
                "vram_mb": to_int(parts[2]),
            }
        )
    return processes


def collect() -> dict:
    if not which("nvidia-smi"):
        return {"available": False}

    query = ",".join(_QUERY_FIELDS)
    out = run(["nvidia-smi", f"--query-gpu={query}", "--format=csv,noheader,nounits"])
    if not out:
        return {"available": False}

    parts = [p.strip() for p in out.split(",")]
    if len(parts) != len(_QUERY_FIELDS):
        return {"available": False}

    (
        util,
        temp,
        vram_used,
        vram_total,
        clock_sm,
        clock_mem,
        power_draw,
        power_limit,
        fan,
        pstate,
        driver_version,
    ) = parts

    vram_used_f = to_float(vram_used)
    vram_total_f = to_float(vram_total)
    vram_pct = (
        round(vram_used_f / vram_total_f * 100, 1)
        if vram_used_f and vram_total_f
        else None
    )

    return {
        "available": True,
        "usage_pct": to_int(util),
        "temp_c": to_int(temp),
        "vram_used_mb": to_int(vram_used),
        "vram_total_mb": to_int(vram_total),
        "vram_pct": vram_pct,
        "clock_sm_mhz": to_int(clock_sm),
        "clock_mem_mhz": to_int(clock_mem),
        "power_draw_w": to_float(power_draw),
        "power_limit_w": to_float(power_limit),
        "fan_pct": to_int(fan) if fan != "[N/A]" else None,
        "pstate": pstate,
        "driver_version": driver_version,
        "processes": _collect_processes(),
    }
