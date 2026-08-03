#!/usr/bin/env python3
"""
monitor.py — background system monitor for Waybar.

Runs continuously, polls all hardware collectors on their own independent
intervals (cheap ones fast, expensive ones slow), and atomically writes a
single JSON snapshot to /tmp/waybar-monitor.json.

Every Waybar module script reads that file only — none of them ever spawn
nvidia-smi / sensors / checkupdates / powerprofilesctl directly, so we never
pay for those subprocess calls more than once per interval, no matter how
many waybar modules or how short waybar's own poll interval is.

Usage:
    ./monitor.py                  # run in foreground (use via systemd, see systemd/)

Intervals are deliberately conservative for the expensive calls:
    - CPU / fans / power-profile / network : every 2s   (cheap, psutil/sysfs)
    - GPU (NVIDIA + AMD) / battery         : every 5s   (subprocess/sysfs)
    - system info (kernel, uptime, ...)    : every 60s  (basically static)
    - checkupdates (pacman-contrib)        : every 1800s (network mirror sync)
"""

import os
import sys
import time
import signal
import logging

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from collectors import (  # noqa: E402
    amd_gpu,
    battery,
    cpu,
    fans,
    network,
    nvidia,
    power_profile,
    system_info,
    updates,
)
from lib.utils import atomic_write_json  # noqa: E402

CACHE_PATH = "/tmp/waybar-monitor.json"
LOG_PATH = os.path.expanduser("~/.cache/waybar-monitor.log")

# Interval in seconds for each collector group.
INTERVAL_FAST = 2
INTERVAL_MEDIUM = 5
INTERVAL_SLOW = 60
INTERVAL_UPDATES = 1800

os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
logging.basicConfig(
    filename=LOG_PATH,
    level=logging.WARNING,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("waybar-monitor")

_running = True


def _handle_signal(signum, frame):
    global _running
    _running = False


def _safe_collect(name, fn):
    """Run a collector, log+swallow any unexpected exception so one broken
    collector (e.g. a GPU driver hiccup) never kills the whole daemon."""
    try:
        return fn()
    except Exception:
        log.exception("collector '%s' failed", name)
        return {"available": False, "error": True}


def main():
    global _running
    signal.signal(signal.SIGTERM, _handle_signal)
    signal.signal(signal.SIGINT, _handle_signal)

    state = {
        "cpu": {},
        "nvidia": {"available": False},
        "amd_gpu": {"available": False},
        "fans": {"available": False},
        "power_profile": {"available": False},
        "battery": {"available": False},
        "network": {"available": False},
        "system": {},
        "updates": {"available": False},
        "_updated_at": 0,
    }

    net_prev_state: dict = {}

    last = {
        "fast": 0.0,
        "medium": 0.0,
        "slow": 0.0,
        "updates": 0.0,
    }

    # First run: prime everything immediately.
    force_first_run = True

    while _running:
        now = time.monotonic()
        dirty = False

        if force_first_run or now - last["fast"] >= INTERVAL_FAST:
            state["cpu"] = _safe_collect("cpu", cpu.collect)
            state["fans"] = _safe_collect("fans", fans.collect)
            state["power_profile"] = _safe_collect("power_profile", power_profile.collect)
            try:
                net_data, net_prev_state = network.collect(net_prev_state)
            except Exception:
                log.exception("collector 'network' failed")
                net_data = {"available": False, "error": True}
            state["network"] = net_data
            last["fast"] = now
            dirty = True

        if force_first_run or now - last["medium"] >= INTERVAL_MEDIUM:
            state["nvidia"] = _safe_collect("nvidia", nvidia.collect)
            state["amd_gpu"] = _safe_collect("amd_gpu", amd_gpu.collect)
            state["battery"] = _safe_collect("battery", battery.collect)
            last["medium"] = now
            dirty = True

        if force_first_run or now - last["slow"] >= INTERVAL_SLOW:
            state["system"] = _safe_collect("system_info", system_info.collect)
            last["slow"] = now
            dirty = True

        if force_first_run or now - last["updates"] >= INTERVAL_UPDATES:
            state["updates"] = _safe_collect("updates", updates.collect)
            last["updates"] = now
            dirty = True

        force_first_run = False

        if dirty:
            state["_updated_at"] = time.time()
            try:
                atomic_write_json(CACHE_PATH, state)
            except Exception:
                log.exception("failed to write cache to %s", CACHE_PATH)

        time.sleep(0.5)

    # Clean shutdown: leave the last good snapshot in place, just note we stopped.
    log.info("waybar-monitor stopped")


if __name__ == "__main__":
    main()
