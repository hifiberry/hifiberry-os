"""Link the selected AES67 source to the default sink.

Links at node level: `pw-link "<source>" "<sink>"` pairs matching ports in
order, so a multi-channel Dante flow naturally routes only as many channels as
the sink accepts.
"""

import logging
import subprocess
import sys
import time

from . import pwgraph, registry, selection, sink as sinkmod

# Distinguishes "caller passed nothing" from "caller explicitly passed None",
# which means "no stream selected" and is a valid, non-error state.
_UNSET = object()


def _resolve(runner, selected):
    objects = pwgraph.dump(runner=runner)
    stream = registry.find(objects, selected) if selected else None
    target = sinkmod.default_sink(objects, runner=runner)
    return objects, stream, target


def connect(runner=subprocess.run, path=None, selected=_UNSET):
    if selected is _UNSET:
        selected = selection.get(path)
    if not selected:
        logging.info("no AES67 stream selected; nothing to link")
        return 0
    _, stream, target = _resolve(runner, selected)
    if not stream:
        print(f"AES67 stream {selected!r} not found", file=sys.stderr)
        return 1
    if not target:
        print("no usable sink found to link into", file=sys.stderr)
        return 1
    result = runner(["pw-link", stream["name"], target], capture_output=True, text=True)
    if result.returncode == 0:
        logging.info("linked %s -> %s", stream["name"], target)
        return 0
    if "File exists" in (result.stderr or ""):
        logging.info("already linked %s -> %s", stream["name"], target)
        return 0
    print(f"failed to link {stream['name']} -> {target}: {result.stderr}", file=sys.stderr)
    return 1


def disconnect(runner=subprocess.run, path=None, selected=_UNSET):
    if selected is _UNSET:
        selected = selection.get(path)
    if not selected:
        return 0
    _, stream, target = _resolve(runner, selected)
    if not stream or not target:
        # Nothing to tear down; do not block `systemctl --user stop`.
        return 0
    runner(["pw-link", "-d", stream["name"], target], capture_output=True, text=True)
    logging.info("unlinked %s -> %s", stream["name"], target)
    return 0


def is_linked(objects, source_name, sink_name):
    """True if any link joins the named source to the named sink.

    Link objects address their endpoints by numeric node id
    ("link.output.node": 39), never by name, so both names are resolved to ids
    first. Comparing names directly silently never matches -- it reports
    "not receiving" while audio is plainly playing.
    """
    source_id = pwgraph.node_id(objects, source_name)
    sink_id = pwgraph.node_id(objects, sink_name)
    if source_id is None or sink_id is None:
        return False
    for obj in objects:
        if obj.get("type") != pwgraph.LINK_TYPE:
            continue
        p = pwgraph.props(obj)
        if (p.get("link.output.node") == source_id
                and p.get("link.input.node") == sink_id):
            return True
    return False


def watch(interval=5, runner=subprocess.run, path=None, selected=_UNSET,
          iterations=None):
    """Keep the selected stream linked, reconciling until stopped.

    A transmitter that is power-cycled, or has AES67 toggled in Dante
    Controller, drops its node out of the graph and brings it back later. A
    one-shot link never recovers from that, so the unit runs this loop instead.
    `iterations` bounds the loop for tests; None means run forever.
    """
    count = 0
    while iterations is None or count < iterations:
        current = selection.get(path) if selected is _UNSET else selected
        if current:
            objects, stream, target = _resolve(runner, current)
            if stream and target and not is_linked(objects, current, target):
                connect(runner=runner, path=path, selected=current)
        count += 1
        if iterations is None or count < iterations:
            time.sleep(interval)
    return 0
