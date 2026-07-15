"""Report real play/stop state to ACR.

The UAC2 node exists whenever the gadget is bound, so node presence says
nothing about whether the host is playing. The ALSA substream state does:
RUNNING means the host has the stream open and is streaming.

Nothing here may assume any particular /proc/asound status path belongs to
the gadget: the target has both a HiFiBerry DAC card and (once bound) a USB
gadget card, and the DAC's own playback must never be mistaken for the
gadget/Mac "playing". Callers are expected to scope discovery with
`monitor.discover_status_paths`'s card_filter -- the same mechanism
monitor.py uses for xrun/rate attribution -- rather than scanning every
card unfiltered.
"""

import json
import logging
import time
import urllib.error
import urllib.request

from .monitor import discover_status_paths, parse_alsa_status

PLAYER_NAME = "usbaudio"


def gadget_stream_state(status_paths):
    """Check ALSA substream status to determine if gadget is streaming.

    Reads each path in status_paths and returns "playing" if any RUNNING
    stream is found, "stopped" otherwise. status_paths should already be
    scoped to the gadget's own card (see `monitor.discover_status_paths`)
    -- this function trusts whatever paths it is given and does no card
    filtering of its own.
    """
    for path in status_paths:
        try:
            with open(path) as handle:
                status = parse_alsa_status(handle.read())
        except OSError:
            continue
        if status["state"] == "RUNNING":
            return "playing"
    return "stopped"


def post_state(state, opener=urllib.request.urlopen, port=1080):
    """POST the current state to ACR's update endpoint.

    Uses stdlib urllib.request rather than shelling out to curl (curl is
    not a declared package dependency). The outcome is always inspected:
    a genuine 2xx response is the only thing logged as success. ACR being
    down, connection refused, or a non-2xx response is logged as a
    failure and swallowed here -- the poll loop must keep running even
    when ACR is temporarily unreachable.

    Args:
        state: "playing" or "stopped"
        opener: callable(Request, timeout=...) for testing (defaults to
            urllib.request.urlopen)
        port: ACR port (defaults to 1080)
    """
    payload = json.dumps({"type": "state_changed", "state": state}).encode("utf-8")
    url = f"http://localhost:{port}/api/player/{PLAYER_NAME}/update"
    request = urllib.request.Request(
        url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with opener(request, timeout=5) as response:
            status = getattr(response, "status", 200)
    except urllib.error.HTTPError as exc:
        logging.warning(
            f"Failed to report state '{state}' to ACR: HTTP {exc.code} {exc.reason}"
        )
        return
    except urllib.error.URLError as exc:
        logging.warning(f"Failed to report state '{state}' to ACR: {exc.reason}")
        return
    except OSError as exc:
        logging.warning(f"Failed to report state '{state}' to ACR: {exc}")
        return

    if 200 <= status < 300:
        logging.info(f"Reported state '{state}' to ACR")
    else:
        logging.warning(
            f"ACR update for state '{state}' returned unexpected status {status}"
        )


def run(interval=5, card_filter=None, base_dir="/proc/asound", poster=post_state,
        sleeper=time.sleep, port=1080):
    """Poll the gadget's substream state forever, posting to ACR only when
    it changes -- ACR should not be spammed every poll interval.

    `card_filter`/`base_dir` are forwarded to
    `monitor.discover_status_paths` on every poll, so state is always
    derived from the gadget's own card rather than any card that happens
    to be RUNNING. The gadget's real card name isn't known until it's
    bound on hardware, so `card_filter` is caller-supplied (typically a
    CLI --card option), never hardcoded here.

    `sleeper` may raise StopIteration to end the loop; real callers never
    do this, it exists so tests can bound an otherwise-infinite loop
    (mirrors monitor.run's runner= idiom).
    """
    last_state = None
    while True:
        status_paths = discover_status_paths(base_dir=base_dir, card_filter=card_filter)
        state = gadget_stream_state(status_paths)
        if state != last_state:
            poster(state, port=port)
            last_state = state
        try:
            sleeper(interval)
        except StopIteration:
            return
