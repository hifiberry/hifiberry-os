"""Follow the settings the web UI writes into ConfigDB.

The UI edits plugin settings through config-server's generic player-settings
endpoint, so nothing in the UI knows about AES67. This module is the other half
of that arrangement: it watches the two ConfigDB keys and applies changes.

`latency` is seeded on first run from the board default (board.py), so the value
the UI shows and the value actually in force agree from the very first page
load, rather than the UI claiming a static descriptor default that the agent
never used.
"""

import logging

from . import board, configdb, configure, selection

LATENCY_KEY = "latency"
STREAM_KEY = "stream"

# Distinguishes "never applied" from "applied as None". The first pass must
# always push ConfigDB's view onto local state, otherwise a stale selection
# file could keep routing a stream the UI believes was cleared.
_UNSET = object()


def seed_latency(db=configdb, model_path=None):
    """Write the board default into ConfigDB if the user has never set it.

    Without this the UI would display the descriptor's static default (one
    number for every board) while the agent quietly used the board-specific one.
    """
    if db.get(db.setting_key(LATENCY_KEY)) is not None:
        return None
    default = (board.default_latency_msec(board.model(model_path)) if model_path
               else board.detect_default_latency())
    if db.set(db.setting_key(LATENCY_KEY), default):
        logging.info("seeded AES67 latency with board default %s ms", default)
        return default
    return None


def _as_latency(raw):
    try:
        value = int(float(raw))
    except (TypeError, ValueError):
        return None
    return value


def apply_once(db=configdb, applied=None, interface=None, runner=None,
               conf_path=None, settings_path=None, state_path=None,
               apply_latency=None, set_selection=None):
    """Apply any ConfigDB change once. Returns the new 'applied' snapshot.

    `applied` carries the last values acted on, so an unchanged poll does no
    work -- applying the latency restarts PipeWire and must not happen on a
    loop.
    """
    applied = dict(applied or {})
    apply_latency = apply_latency or configure.apply_latency
    set_selection = set_selection or selection.set

    reachable, raw_latency = db.fetch(db.setting_key(LATENCY_KEY))
    if not reachable:
        # config-server is down or restarting. Keep whatever is in force rather
        # than mistaking silence for "the user cleared everything".
        logging.debug("ConfigDB unreachable; leaving AES67 settings untouched")
        return applied
    latency = _as_latency(raw_latency)
    if latency is not None and latency != applied.get(LATENCY_KEY):
        try:
            kwargs = {"interface": interface}
            if runner is not None:
                kwargs["runner"] = runner
            if conf_path is not None:
                kwargs["conf_path"] = conf_path
            if settings_path is not None:
                kwargs["settings_path"] = settings_path
            apply_latency(latency, **kwargs)
            applied[LATENCY_KEY] = latency
            logging.info("applied AES67 latency %s ms from ConfigDB", latency)
        except ValueError as exc:
            # config-server validates the range, but a hand-edited ConfigDB can
            # still hold nonsense; refusing beats wedging the audio graph.
            logging.warning("ignoring invalid AES67 latency %r: %s", latency, exc)

    stream_reachable, raw_stream = db.fetch(db.setting_key(STREAM_KEY))
    if not stream_reachable:
        return applied
    stream = raw_stream or None
    if stream != applied.get(STREAM_KEY, _UNSET):
        set_selection(stream, state_path) if state_path else set_selection(stream)
        applied[STREAM_KEY] = stream
        logging.info("applied AES67 stream selection %r from ConfigDB", stream)

    return applied


def run(interval=5, db=configdb, interface=None, iterations=None, **kwargs):
    """Poll ConfigDB and apply changes until stopped.

    `iterations` bounds the loop for tests; None means run forever.
    """
    import time

    applied = None
    count = 0
    while iterations is None or count < iterations:
        try:
            applied = apply_once(db=db, applied=applied, interface=interface,
                                 **kwargs)
        except Exception as exc:  # noqa: BLE001 - the agent must not die here
            logging.warning("AES67 settings sync failed: %s", exc)
        count += 1
        if iterations is None or count < iterations:
            time.sleep(interval)
    return 0
