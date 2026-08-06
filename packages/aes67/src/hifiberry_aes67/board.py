"""Board detection, used only to pick a sensible default receive latency.

The right buffer depth is board-dependent and was measured, not guessed:

* CM5 / Pi 5 hold 3 ms cleanly -- a 35-minute soak matched a no-AES67 control
  run (2 source / 1 DAC xrun).
* A Pi 4 at 3 ms produced 1320 xruns and audibly choppy playback; at 20 ms it
  produced none. Its slower SoC and bcmgenet NIC simply need more headroom.

Unknown hardware gets the conservative value: a user who wants lower latency can
lower it in the web UI, but a device that stutters out of the box reads as
broken.
"""

import logging

LOW_LATENCY_MSEC = 3
CONSERVATIVE_LATENCY_MSEC = 20

DEFAULT_MODEL_PATH = "/proc/device-tree/model"

# Substrings matched case-insensitively against the device-tree model string.
_LOW_LATENCY_BOARDS = ("compute module 5", "pi 5")
_CONSERVATIVE_BOARDS = ("compute module 4", "pi 4")


def model(path=DEFAULT_MODEL_PATH):
    """Return the device-tree model string, or None if it cannot be read."""
    try:
        with open(path, "rb") as handle:
            # Device-tree strings are NUL-terminated.
            return handle.read().decode("utf-8", "replace").rstrip("\x00").strip()
    except (OSError, FileNotFoundError):
        return None


def default_latency_msec(model_string=None):
    if not model_string:
        return CONSERVATIVE_LATENCY_MSEC
    lowered = model_string.lower()
    for needle in _LOW_LATENCY_BOARDS:
        if needle in lowered:
            return LOW_LATENCY_MSEC
    for needle in _CONSERVATIVE_BOARDS:
        if needle in lowered:
            return CONSERVATIVE_LATENCY_MSEC
    logging.info("unrecognised board %r; using conservative AES67 latency",
                 model_string)
    return CONSERVATIVE_LATENCY_MSEC


def detect_default_latency(path=DEFAULT_MODEL_PATH):
    return default_latency_msec(model(path))
