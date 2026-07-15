"""Report real play/stop state to ACR.

The UAC2 node exists whenever the gadget is bound, so node presence says
nothing about whether the host is playing. The ALSA substream state does:
RUNNING means the host has the stream open and is streaming.
"""

import json
import logging
import subprocess

from .monitor import parse_alsa_status

PLAYER_NAME = "usbaudio"


def gadget_stream_state(status_paths):
    """Check ALSA substream status to determine if gadget is streaming.

    Reads each path in status_paths (typically /proc/asound/.../status files)
    and returns "playing" if any RUNNING stream is found, "stopped" otherwise.
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


def post_state(state, runner=subprocess.run, port=1080):
    """POST the current state to ACR's update endpoint.

    Args:
        state: "playing" or "stopped"
        runner: callable for testing (defaults to subprocess.run)
        port: ACR port (defaults to 1080)
    """
    payload = json.dumps({"type": "state_changed", "state": state})
    runner(
        [
            "curl", "-s", "-X", "POST",
            f"http://localhost:{port}/api/player/{PLAYER_NAME}/update",
            "-H", "Content-Type: application/json",
            "-d", payload,
        ],
        capture_output=True,
        text=True,
    )
    logging.info(f"Reported state '{state}' to ACR")
