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

# Measured on a CM5 (BCM2712) with the UAC2 gadget bound: `pw-cli ls Node`
# reported the gadget's capture node as
# "alsa_input.platform-1000480000.usb.stereo-fallback", where
# "1000480000.usb" is the dwc2 USB controller's platform-device address on
# CM5/Pi 5. That address is NOT the same on every Pi that supports gadget
# mode -- Pi 4/CM4 exposes the same dwc2 controller at "7e980000.usb"
# instead -- so this prefix is CM5-specific and will silently fail to match
# (connect() logs "gadget node not found") on Pi 4/CM4 hardware. That is a
# known, deliberate limitation, not an oversight: find_node_by_prefix() only
# does a plain startswith() match, and the varying controller address sits
# in the *middle* of the node name (right after "platform-", before
# ".usb..."), not at either end. A prefix generic enough to skip that
# address (e.g. just "alsa_input.platform-") would also match
# "alsa_input.platform-soc_107c000000_sound.stereo-fallback" -- the DAC's
# own ADC -- which `find_node_by_prefix` would then happily return instead
# of (or before) the real gadget node, wiring the DAC's ADC into its own
# sink as a feedback loop. Excluding that node correctly and staying
# board-portable both at once is not possible with a single startswith
# prefix, so this pins the safest option: exact-enough to guarantee no
# feedback loop on the hardware that has actually been verified (CM5), at
# the known cost of not working out of the box on Pi 4/CM4. UNVERIFIED:
# behavior on Pi 4/CM4 (and any other board whose dwc2 address differs from
# both "1000480000.usb" and "7e980000.usb"). If/when Pi 4/CM4 bring-up
# happens, either add board detection (e.g. read the bound UDC name from
# /sys/class/udc, as gadget.find_udc() already does, and build the prefix
# from that at runtime) or extend the match beyond a plain prefix.
GADGET_NODE_PREFIX = "alsa_input.platform-1000480000.usb."
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


def find_node_exact(name, nodes):
    for n in nodes:
        if n == name:
            return n
    return None


def link_pairs(source, target):
    return [(f"{source}:{src}", f"{target}:{dst}") for src, dst in CHANNELS]


def _resolve(runner, retry=True):
    attempts = RETRY_COUNT + 1 if retry else 1
    for attempt in range(attempts):
        nodes = list_nodes(runner=runner)
        gadget = find_node_by_prefix(GADGET_NODE_PREFIX, nodes)
        target = find_node_exact(TARGET_NODE, nodes)
        if gadget and target:
            return gadget, target
        if attempt < attempts - 1:
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
    # Deliberately no retries: waiting to tear down a link that is already
    # gone just delays `systemctl --user stop`.
    gadget, target = _resolve(runner, retry=False)
    if not gadget or not target:
        print("Required nodes not found", file=sys.stderr)
        return 1
    for src, dst in link_pairs(gadget, target):
        runner(["pw-link", "-d", src, dst], capture_output=True, text=True)
        logging.info(f"Disconnected {src} -> {dst}")
    return 0
