"""User-adjustable AES67 settings.

Currently just the receive latency. Stored separately from the selected stream
because the two have different lifetimes: the selection changes whenever the
user picks another transmitter, the latency is a tuning knob they set once.

A stored value of None means "follow the board default" (see board.py), which is
different from having no file at all only in that the user has been here.
"""

import json
import logging
import os

# PipeWire will accept much wider values, but outside this range the result is
# either unusable (below ~1ms nothing sustains) or absurd for a listening
# endpoint. Bounding it keeps a typo in the web UI from wedging the audio graph.
MIN_LATENCY_MSEC = 1
MAX_LATENCY_MSEC = 500


def default_path():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(base, "hifiberry-aes67", "settings.json")


def _read(path):
    try:
        with open(path) as handle:
            data = json.load(handle)
            return data if isinstance(data, dict) else {}
    except FileNotFoundError:
        return {}
    except (ValueError, TypeError, OSError):
        logging.warning("settings file %s unreadable; using defaults", path)
        return {}


def _write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as handle:
        json.dump(data, handle)
    os.replace(tmp, path)


def is_overridden(path=None):
    """True if the user has chosen a latency rather than following the board."""
    return _read(path or default_path()).get("latency_msec") is not None


def latency_msec(path=None, board_default=None):
    stored = _read(path or default_path()).get("latency_msec")
    if isinstance(stored, int) and MIN_LATENCY_MSEC <= stored <= MAX_LATENCY_MSEC:
        return stored
    if board_default is None:
        from . import board as board_mod
        board_default = board_mod.detect_default_latency()
    return board_default


def set_latency(value, path=None):
    """Set the latency override. None restores the board default."""
    path = path or default_path()
    if value is not None:
        if isinstance(value, bool) or not isinstance(value, int):
            raise ValueError("latency must be an integer number of milliseconds")
        if not MIN_LATENCY_MSEC <= value <= MAX_LATENCY_MSEC:
            raise ValueError(
                f"latency must be between {MIN_LATENCY_MSEC} and "
                f"{MAX_LATENCY_MSEC} ms"
            )
    data = _read(path)
    data["latency_msec"] = value
    _write(path, data)
