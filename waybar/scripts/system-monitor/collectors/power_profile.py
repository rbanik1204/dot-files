"""
collectors/power_profile.py

Wraps `powerprofilesctl` (power-profiles-daemon) for both:
- read-only status collection (used by the background daemon)
- mutation helpers (used directly by the waybar power-profile module on click,
  NOT through the cache, since a click should act immediately)

Profiles as reported by power-profiles-daemon: "performance", "balanced",
"power-saver".
"""

from lib.utils import run, which

PROFILE_ORDER = ["balanced", "performance", "power-saver"]


def collect() -> dict:
    if not which("powerprofilesctl"):
        return {"available": False, "current": None, "profiles": []}

    current = run(["powerprofilesctl", "get"])
    listing = run(["powerprofilesctl", "list"])

    profiles = []
    if listing:
        for line in listing.splitlines():
            line = line.strip()
            if line.startswith("*") or line.startswith("-") or ":" in line:
                # lines look like "  performance" or "* balanced" or "  power-saver:"
                name = line.lstrip("*- ").split(":")[0].strip()
                if name in ("performance", "balanced", "power-saver"):
                    profiles.append(name)

    return {
        "available": True,
        "current": current,
        "profiles": profiles or PROFILE_ORDER,
    }


def set_profile(name: str) -> bool:
    if name not in ("performance", "balanced", "power-saver"):
        return False
    return run(["powerprofilesctl", "set", name]) is not None


def set_performance() -> bool:
    return set_profile("performance")


def set_balanced() -> bool:
    return set_profile("balanced")


def set_power_saver() -> bool:
    return set_profile("power-saver")


def toggle() -> str | None:
    """Cycle balanced -> performance -> power-saver -> balanced -> ..."""
    current = run(["powerprofilesctl", "get"])
    if current not in PROFILE_ORDER:
        current = "balanced"
    next_profile = PROFILE_ORDER[(PROFILE_ORDER.index(current) + 1) % len(PROFILE_ORDER)]
    if set_profile(next_profile):
        return next_profile
    return None
