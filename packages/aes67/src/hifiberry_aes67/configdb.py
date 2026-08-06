"""Read and write plugin settings in config-server's ConfigDB.

The web UI writes plugin settings through config-server's generic
`/api/v1/players/<service>/settings` endpoint, which stores them in ConfigDB
under `player.<service>.<key>`. This module is how the agent reads them back,
so the UI does not need to know anything AES67-specific.

Only reachable on localhost, and unauthenticated there: the auth gateway sits
in nginx, not in config-server itself.
"""

import json
import logging
import urllib.request

CONFIG_SERVER = "http://localhost:1081"
SERVICE = "aes67"
TIMEOUT = 5


def setting_key(key):
    """The ConfigDB key config-server stores this plugin's setting under."""
    return f"player.{SERVICE}.{key}"


def fetch(key, opener=None):
    """Return (reachable, value).

    Callers must distinguish "config-server is down" from "the key is unset":
    treating the first as the second would let a config-server restart clear
    the user's stream selection and stop playback.

    An unset key answers 404, which urllib raises as HTTPError -- that is a
    successful conversation with the server, so reachable stays True.
    """
    opener = opener or urllib.request.urlopen
    url = f"{CONFIG_SERVER}/api/v1/key/{key}"
    try:
        with opener(url, timeout=TIMEOUT) as response:
            payload = json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return True, None
        logging.debug("ConfigDB get %s failed: %s", key, exc)
        return False, None
    except Exception as exc:  # noqa: BLE001 - transport failure
        logging.debug("ConfigDB get %s unreachable: %s", key, exc)
        return False, None
    if not isinstance(payload, dict) or payload.get("status") != "success":
        return True, None
    value = (payload.get("data") or {}).get("value")
    return True, (None if value is None else str(value))


def get(key, opener=None):
    """Return the stored string value, or None if unset or unreachable."""
    return fetch(key, opener=opener)[1]


def set(key, value, opener=None):  # noqa: A001 - mirrors get()
    """Store a value. Returns True on success."""
    opener = opener or urllib.request.urlopen
    request = urllib.request.Request(
        f"{CONFIG_SERVER}/api/v1/key/{key}",
        data=json.dumps({"value": str(value)}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with opener(request, timeout=TIMEOUT) as response:
            payload = json.loads(response.read().decode())
    except Exception as exc:  # noqa: BLE001 - config-server may be restarting
        logging.debug("ConfigDB set %s failed: %s", key, exc)
        return False
    return isinstance(payload, dict) and payload.get("status") == "success"
