"""Report play/stop to audiocontrol (ACR).

A multicast receiver has no transport control, so the ACR player declares only
play/stop -- the same honest capability set usbaudio uses. "playing" means the
selected stream is linked to the sink; RTP is always flowing regardless, so link
state is the only meaningful signal.
"""

import json
import logging
import subprocess
import time
import urllib.request

from . import linker, pwgraph, registry, selection, sink as sinkmod

PLAYER_NAME = "aes67"
DEFAULT_ACR_PORT = 1080


def current_state(objects, selected, target):
    if not selected or not target:
        return "stopped"
    if not registry.find(objects, selected):
        return "stopped"
    return "playing" if linker.is_linked(objects, selected, target) else "stopped"


def post_state(state_name, port=DEFAULT_ACR_PORT, opener=None):
    opener = opener or urllib.request.urlopen
    payload = json.dumps({"type": "state_changed", "state": state_name}).encode()
    request = urllib.request.Request(
        f"http://localhost:{port}/api/player/{PLAYER_NAME}/update",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with opener(request, timeout=5):
            return True
    except Exception as exc:  # noqa: BLE001 - ACR being down must not kill the agent
        logging.debug("ACR update failed: %s", exc)
        return False


def run(interval=5, port=DEFAULT_ACR_PORT, runner=subprocess.run, path=None,
        iterations=None, resync_after=12):
    """Poll link state and report it to ACR.

    Posts on every transition, and additionally re-posts every `resync_after`
    polls even when nothing changed. The resync is not redundant: audiocontrol
    resets each player to its configured initial_state when it restarts, so a
    transition-only reporter leaves ACR permanently showing "stopped" while
    audio is playing -- there is no further transition to trigger a correction.
    A failed post also forces a retry on the next poll.

    `iterations` bounds the loop for tests; None means run forever.
    """
    last = None
    since_post = 0
    count = 0
    while iterations is None or count < iterations:
        objects = pwgraph.dump(runner=runner)
        selected = selection.get(path)
        target = sinkmod.default_sink(objects, runner=runner)
        now = current_state(objects, selected, target)
        if now != last or since_post >= resync_after:
            if now != last:
                logging.info("state -> %s", now)
            last = now if post_state(now, port=port) else None
            since_post = 0
        else:
            since_post += 1
        count += 1
        if iterations is None or count < iterations:
            time.sleep(interval)
    return 0
