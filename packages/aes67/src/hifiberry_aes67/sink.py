"""Resolve which sink AES67 audio should be linked into.

Two hazards this exists to avoid:

* "input-processor" is /usr/lib/ladspa/riaa.so -- the Analog Input Processor's
  vinyl RIAA phono EQ curve. Its inviting name makes it a natural-looking
  target; routing network audio through it applies a phono correction curve.
  usbaudio's linker.py carries the same warning.
* The ALSA sink name is board-specific: a Digi+ exposes "...iec958-stereo"
  where an analogue DAC exposes "...stereo-fallback". Neither may be hardcoded.
"""

import json
import logging
import re
import subprocess

from . import pwgraph

FORBIDDEN_TARGETS = ("input-processor", "input-processor.output")

_METADATA_RE = re.compile(r"key:'default\.audio\.sink'\s+value:'([^']*)'")


def _sink_names(objects):
    names = []
    for node in pwgraph.nodes(objects):
        p = pwgraph.props(node)
        if p.get("media.class") != "Audio/Sink":
            continue
        name = p.get("node.name")
        if name and name not in FORBIDDEN_TARGETS:
            names.append(name)
    return names


def _metadata_default(runner):
    try:
        result = runner(["pw-metadata"], capture_output=True, text=True)
    except (OSError, FileNotFoundError):
        return None
    if result.returncode != 0:
        return None
    match = _METADATA_RE.search(result.stdout or "")
    if not match:
        return None
    try:
        return (json.loads(match.group(1)) or {}).get("name")
    except (ValueError, TypeError):
        return None


def default_sink(objects, runner=subprocess.run):
    """Best sink to link AES67 audio into, or None if there is no usable sink."""
    candidates = _sink_names(objects)
    preferred = _metadata_default(runner)
    if preferred in FORBIDDEN_TARGETS:
        logging.warning(
            "default.audio.sink is %s (RIAA phono EQ); ignoring it", preferred
        )
        preferred = None
    if preferred and preferred in candidates:
        return preferred
    if preferred:
        logging.info("default sink %s not present in graph; falling back", preferred)
    for name in candidates:
        if name.startswith("alsa_output."):
            return name
    return candidates[0] if candidates else None
