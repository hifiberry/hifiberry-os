"""Apply settings to PipeWire: render the drop-in, restart only if it changed.

Kept separate from pwconf (which only knows how to render and write a file) and
from settings (which only stores a number) because this is the module with the
disruptive side effect -- restarting PipeWire interrupts whatever is playing, so
it must happen only when the generated config actually differs.
"""

import logging
import subprocess

from . import board, pwconf, settings


def restart_pipewire(runner=subprocess.run):
    try:
        result = runner(["systemctl", "--user", "restart", "pipewire"],
                        capture_output=True, text=True)
    except (OSError, FileNotFoundError):
        logging.warning("systemctl not available; cannot restart PipeWire")
        return False
    if result.returncode != 0:
        logging.warning("PipeWire restart failed: %s", getattr(result, "stderr", ""))
        return False
    return True


def current(settings_path=None, model_path=None):
    """The effective settings, without touching anything."""
    board_default = (board.detect_default_latency(model_path) if model_path
                     else board.detect_default_latency())
    return {
        "latency_msec": settings.latency_msec(settings_path,
                                              board_default=board_default),
        "board_default_msec": board_default,
        "overridden": settings.is_overridden(settings_path),
    }


def ensure(interface=None, runner=subprocess.run, conf_path=None,
           settings_path=None, model_path=None, restart=True):
    """Make the PipeWire drop-in match the current settings.

    Returns the effective settings plus whether PipeWire was restarted.
    """
    interface = interface or "eth0"
    state = current(settings_path=settings_path, model_path=model_path)
    changed = pwconf.write(conf_path or pwconf.default_path(),
                           state["latency_msec"], interface)
    restarted = bool(changed and restart and restart_pipewire(runner))
    if pwconf.legacy_system_dropin_present():
        logging.warning(
            "%s still exists; it loads a second rtp-sap module. Remove it.",
            pwconf.LEGACY_SYSTEM_PATH)
    state["changed"] = changed
    state["restarted"] = restarted
    state["interface"] = interface
    return state


def apply_latency(value, interface=None, runner=subprocess.run, conf_path=None,
                  settings_path=None, model_path=None, restart=True):
    """Persist a latency override (None = board default) and apply it."""
    settings.set_latency(value, settings_path)
    return ensure(interface=interface, runner=runner, conf_path=conf_path,
                  settings_path=settings_path, model_path=model_path,
                  restart=restart)
