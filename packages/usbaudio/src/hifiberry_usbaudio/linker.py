"""Link the UAC2 gadget capture node to the HiFiBerry DAC sink.

Deliberately links straight to the DAC sink: 'input-processor' is
/usr/lib/ladspa/riaa.so, a vinyl RIAA phono EQ curve, and would corrupt USB
audio. 'speakereq2x2' (speaker EQ) is bypassed as a consequence -- change
TARGET_NODE to route through it if that is wanted.
"""

import logging
import subprocess
import sys
import time

# Determined empirically on hardware once the gadget is bound (see plan Task 7).
GADGET_NODE_PREFIX = "alsa_input.usb-gadget"
TARGET_NODE = "alsa_output.platform-soc_107c000000_sound.stereo-fallback"

CHANNELS = (("capture_FL", "playback_FL"), ("capture_FR", "playback_FR"))
RETRY_COUNT = 2
RETRY_DELAY = 3


def list_nodes(runner=subprocess.run):
    result = runner(["pw-cli", "ls", "Node"], capture_output=True, text=True)
    nodes = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if line.startswith("node.name ="):
            nodes.append(line.split('"')[1])
    return nodes


def find_node_by_prefix(prefix, nodes):
    for name in nodes:
        if name.startswith(prefix):
            return name
    return None


def link_pairs(source, target):
    return [(f"{source}:{src}", f"{target}:{dst}") for src, dst in CHANNELS]


def _resolve(runner):
    for attempt in range(RETRY_COUNT + 1):
        nodes = list_nodes(runner=runner)
        gadget = find_node_by_prefix(GADGET_NODE_PREFIX, nodes)
        target = find_node_by_prefix(TARGET_NODE, nodes)
        if gadget and target:
            return gadget, target
        if attempt < RETRY_COUNT:
            time.sleep(RETRY_DELAY)
    return None, None


def connect(runner=subprocess.run):
    gadget, target = _resolve(runner)
    if not gadget:
        print("USB gadget audio node not found -- is the gadget bound?", file=sys.stderr)
        return 1
    if not target:
        print(f"DAC sink {TARGET_NODE} not found", file=sys.stderr)
        return 1

    for src, dst in link_pairs(gadget, target):
        res = runner(["pw-link", src, dst], capture_output=True, text=True)
        if res.returncode == 0:
            logging.info(f"Connected {src} -> {dst}")
        elif "File exists" in (res.stderr or ""):
            logging.info(f"Already connected {src} -> {dst}")
        else:
            print(f"Failed to connect {src} -> {dst}: {res.stderr}", file=sys.stderr)
            return 1
    return 0


def disconnect(runner=subprocess.run):
    gadget, target = _resolve(runner)
    if not gadget or not target:
        print("Required nodes not found", file=sys.stderr)
        return 1
    for src, dst in link_pairs(gadget, target):
        runner(["pw-link", "-d", src, dst], capture_output=True, text=True)
        logging.info(f"Disconnected {src} -> {dst}")
    return 0
