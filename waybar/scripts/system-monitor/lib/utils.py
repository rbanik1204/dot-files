"""
lib/utils.py

Shared helpers used by every collector:
- safe subprocess execution with timeouts (never let one bad command hang the daemon)
- safe numeric parsing
- atomic JSON writes (so waybar never reads a half-written file)

Keeping this in one place means every collector fails the same, predictable way.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from typing import Optional


def run(cmd: list[str], timeout: float = 2.0) -> Optional[str]:
    """
    Run a command and return stdout (stripped), or None on any failure
    (missing binary, timeout, non-zero exit, permission error, etc).

    Collectors should never raise because of this call.
    """
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=timeout,
            text=True,
        )
        if result.returncode != 0:
            return None
        return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None


def which(binary: str) -> bool:
    """Cheap existence check so we don't repeatedly try missing binaries."""
    return shutil.which(binary) is not None


def to_float(value, default=None):
    """Parse a string/number to float, returning `default` on failure."""
    try:
        if value is None:
            return default
        return float(str(value).strip())
    except (ValueError, TypeError):
        return default


def to_int(value, default=None):
    try:
        if value is None:
            return default
        return int(float(str(value).strip()))
    except (ValueError, TypeError):
        return default


def read_sysfs(path: str) -> Optional[str]:
    """Read a single-line sysfs file, returning None if unreadable."""
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except (FileNotFoundError, PermissionError, OSError):
        return None


def read_sysfs_float(path: str, scale: float = 1.0) -> Optional[float]:
    raw = read_sysfs(path)
    val = to_float(raw)
    return val / scale if val is not None else None


def atomic_write_json(path: str, data: dict) -> None:
    """
    Write JSON atomically: write to a temp file in the same directory,
    then os.replace() it over the target. This guarantees any reader
    (waybar module scripts) only ever sees a complete, valid file.
    """
    directory = os.path.dirname(path) or "."
    fd, tmp_path = tempfile.mkstemp(prefix=".waybar-monitor-", dir=directory)
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(data, f, indent=None, separators=(",", ":"))
        os.replace(tmp_path, path)
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def load_cache(path: str) -> dict:
    """Read the monitor cache; return {} if missing/corrupt (daemon not started yet)."""
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}
