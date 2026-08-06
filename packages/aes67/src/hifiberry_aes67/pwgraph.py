"""The only module that shells out to pw-dump.

Everything else operates on the parsed objects, which keeps the rest of the
package testable without PipeWire running.
"""

import json
import logging
import subprocess

NODE_TYPE = "PipeWire:Interface:Node"
LINK_TYPE = "PipeWire:Interface:Link"


def dump(runner=subprocess.run):
    """Return the PipeWire graph as a list of objects, or [] if unavailable."""
    try:
        result = runner(["pw-dump"], capture_output=True, text=True)
    except (OSError, FileNotFoundError):
        logging.warning("pw-dump not available")
        return []
    if result.returncode != 0:
        logging.warning("pw-dump failed: %s", getattr(result, "stderr", ""))
        return []
    try:
        parsed = json.loads(result.stdout)
    except (ValueError, TypeError):
        logging.warning("pw-dump returned unparseable JSON")
        return []
    return parsed if isinstance(parsed, list) else []


def nodes(objects):
    return [o for o in objects if o.get("type") == NODE_TYPE]


def props(obj):
    return (obj.get("info") or {}).get("props") or {}


def node_id(objects, name):
    """Resolve a node name to its numeric id, or None.

    Link objects reference endpoints by numeric id (link.output.node = 39), not
    by name, so anything inspecting links has to translate first.
    """
    for node in nodes(objects):
        if props(node).get("node.name") == name:
            return node.get("id")
    return None
