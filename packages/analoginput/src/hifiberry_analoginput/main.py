#!/usr/bin/env python3

import argparse
import subprocess
import sys
import time

# Configuration
ADC_NODE_PREFIX = "alsa_input.platform-soc"
FX_NODE_NAME = "effect_input.proc"
RETRY_COUNT = 2
RETRY_DELAY = 3

CHANNELS = {
    "FL": ("capture_FL", "playback_FL"),
    "FR": ("capture_FR", "playback_FR"),
}

VERBOSE = False


def vlog(msg):
    if VERBOSE:
        print(msg)


def info(msg):
    print(msg)


def run(cmd):
    vlog("+ " + " ".join(cmd))
    return subprocess.run(cmd, text=True, capture_output=True)


def list_nodes():
    try:
        out = subprocess.check_output(["pw-cli", "ls", "Node"], text=True)
    except subprocess.CalledProcessError:
        return []

    nodes = []
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("node.name ="):
            nodes.append(line.split('"')[1])
    return nodes


def find_node_by_prefix(prefix):
    for name in list_nodes():
        if name.startswith(prefix):
            vlog(f"Found node: {name}")
            return name
    return None


def find_node_exact(name):
    for n in list_nodes():
        if n == name:
            vlog(f"Found node: {name}")
            return name
    return None


def connect():
    adc = None
    fx = None
    
    # Retry mechanism for finding nodes
    for attempt in range(RETRY_COUNT + 1):
        adc = find_node_by_prefix(ADC_NODE_PREFIX)
        fx = find_node_exact(FX_NODE_NAME)
        
        if adc and fx:
            break
            
        if attempt < RETRY_COUNT:
            missing = []
            if not adc:
                missing.append("ADC node")
            if not fx:
                missing.append("Effect input node")
            vlog(f"Attempt {attempt + 1}/{RETRY_COUNT + 1}: {', '.join(missing)} not found, retrying in {RETRY_DELAY}s...")
            time.sleep(RETRY_DELAY)
    
    if not adc:
        print("ADC node not found after retries", file=sys.stderr)
        sys.exit(1)

    if not fx:
        print("Effect input node not found after retries", file=sys.stderr)
        sys.exit(1)

    created_any = False

    for ch, (src_port, dst_port) in CHANNELS.items():
        src = f"{adc}:{src_port}"
        dst = f"{fx}:{dst_port}"

        res = run(["pw-link", src, dst])

        if res.returncode == 0:
            info(f"Connected {ch}: {src} -> {dst}")
            created_any = True
        else:
            # pw-link returns non-zero if link already exists
            if "File exists" in res.stderr:
                info(f"Already connected {ch}: {src} -> {dst}")
                created_any = True
            else:
                print(f"Failed to connect {ch}", file=sys.stderr)
                print(res.stderr.strip(), file=sys.stderr)
                sys.exit(1)

    sys.exit(0)


def disconnect():
    adc = find_node_by_prefix(ADC_NODE_PREFIX)
    fx = find_node_exact(FX_NODE_NAME)

    if not adc or not fx:
        print("Required nodes not found", file=sys.stderr)
        sys.exit(1)

    removed_any = False

    for ch, (src_port, dst_port) in CHANNELS.items():
        src = f"{adc}:{src_port}"
        dst = f"{fx}:{dst_port}"

        res = run(["pw-link", "-d", src, dst])

        if res.returncode == 0:
            info(f"Disconnected {ch}: {src} -> {dst}")
            removed_any = True
        else:
            info(f"No link for {ch}")

    if not removed_any:
        info("No links were connected")

    sys.exit(0)


def main():
    global VERBOSE

    parser = argparse.ArgumentParser(
        description="Connect or disconnect ALSA ADC to effect_input.proc using pw-link"
    )
    parser.add_argument("action", choices=("connect", "disconnect"))
    parser.add_argument("-v", "--verbose", action="store_true")

    args = parser.parse_args()
    VERBOSE = args.verbose

    if args.action == "connect":
        connect()
    else:
        disconnect()


if __name__ == "__main__":
    main()
