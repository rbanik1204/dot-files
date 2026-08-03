"""
collectors/network.py

Network info: SSID, signal strength, live up/down throughput, local IP,
gateway, and VPN detection.

Throughput requires a delta between two points in time, so `collect()`
takes and returns a small state dict that monitor.py persists across ticks
(no global state inside the module itself -> easier to test/reason about).
"""

import time

import psutil

from lib.utils import run, to_int, which

VPN_INTERFACE_PREFIXES = ("tun", "wg", "ppp", "tap")


def _default_iface() -> str | None:
    out = run(["ip", "-o", "route", "get", "1.1.1.1"], timeout=1.0)
    if not out:
        return None
    tokens = out.split()
    if "dev" in tokens:
        return tokens[tokens.index("dev") + 1]
    return None


def _gateway() -> str | None:
    out = run(["ip", "route", "show", "default"], timeout=1.0)
    if not out:
        return None
    tokens = out.split()
    if "via" in tokens:
        return tokens[tokens.index("via") + 1]
    return None


def _local_ip(iface: str) -> str | None:
    addrs = psutil.net_if_addrs().get(iface, [])
    for addr in addrs:
        if addr.family.name == "AF_INET":
            return addr.address
    return None


def _wifi_info(iface: str) -> dict:
    """SSID + signal strength via `iw`. Returns empty dict on wired/unavailable."""
    if not which("iw"):
        return {}
    out = run(["iw", "dev", iface, "link"], timeout=1.0)
    if not out or "Not connected" in out:
        return {}

    ssid = None
    signal_dbm = None
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("SSID:"):
            ssid = line.split("SSID:", 1)[1].strip()
        elif line.startswith("signal:"):
            # e.g. "signal: -52 dBm"
            signal_dbm = to_int(line.split("signal:", 1)[1].strip().split()[0])

    return {"ssid": ssid, "signal_dbm": signal_dbm}


def _vpn_active() -> bool:
    for iface in psutil.net_if_addrs().keys():
        if iface.startswith(VPN_INTERFACE_PREFIXES):
            return True
    return False


def collect(prev_state: dict | None = None) -> tuple[dict, dict]:
    prev_state = prev_state or {}
    iface = _default_iface()

    now = time.monotonic()
    counters = psutil.net_io_counters(pernic=True)

    down_kbps = up_kbps = None
    new_state = {"ts": now}

    if iface and iface in counters:
        rx = counters[iface].bytes_recv
        tx = counters[iface].bytes_sent
        new_state[iface] = {"rx": rx, "tx": tx}

        prev = prev_state.get(iface)
        prev_ts = prev_state.get("ts")
        if prev and prev_ts and now > prev_ts:
            dt = now - prev_ts
            down_kbps = round((rx - prev["rx"]) / 1024 / dt, 1)
            up_kbps = round((tx - prev["tx"]) / 1024 / dt, 1)

    data = {
        "available": iface is not None,
        "interface": iface,
        "download_kbps": down_kbps,
        "upload_kbps": up_kbps,
        "local_ip": _local_ip(iface) if iface else None,
        "gateway": _gateway(),
        "vpn_active": _vpn_active(),
    }

    if iface:
        data.update(_wifi_info(iface))

    return data, new_state
