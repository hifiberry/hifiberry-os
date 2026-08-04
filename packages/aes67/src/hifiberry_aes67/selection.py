"""Persist which AES67 stream is selected.

Stored by SAP session name rather than PipeWire node id, so the choice survives
reboots and node renumbering. The agent is the sole reader and writer -- the Web
UI reaches it through this package's REST API -- so this is deliberately a plain
user state file rather than ConfigDB, which would add a runtime dependency on
config-server for no extra reachability.
"""

import json
import logging
import os


def default_path():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(base, "hifiberry-aes67", "selection.json")


def get(path=None):
    path = path or default_path()
    try:
        with open(path) as handle:
            return (json.load(handle) or {}).get("stream")
    except FileNotFoundError:
        return None
    except (ValueError, TypeError, OSError):
        logging.warning("selection file %s unreadable; treating as unset", path)
        return None


def set(name, path=None):  # noqa: A001 - deliberate module-level verb
    path = path or default_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as handle:
        json.dump({"stream": name}, handle)
    os.replace(tmp, path)
