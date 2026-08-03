"""
collectors/updates.py

Number of pending Arch package updates via `checkupdates` (pacman-contrib).
This is the most expensive collector (it syncs a temp pacman db against a
mirror), so monitor.py runs it on a much longer interval than everything
else (default: every 30 minutes, configurable).
"""

from lib.utils import run, which


def collect() -> dict:
    if not which("checkupdates"):
        return {"available": False, "count": None, "packages": []}

    out = run(["checkupdates"], timeout=20.0)
    if out is None:
        # checkupdates exits non-zero with no output when there are 0 updates
        return {"available": True, "count": 0, "packages": []}

    lines = [l for l in out.splitlines() if l.strip()]
    packages = [line.split()[0] for line in lines if line.split()]
    return {"available": True, "count": len(lines), "packages": packages}
