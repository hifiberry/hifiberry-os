"""Glitch instrumentation for USB gadget audio.

An xrun count with no sample rate attached is not actionable -- the whole point
is to learn which rates hold and which fall apart, so every report carries the
negotiated rate.
"""

import glob
import json
import logging
import subprocess
import time


def parse_alsa_status(text):
    """Parse /proc/asound/card*/pcm*/sub*/status."""
    status = {"state": None, "rate": None}
    for line in text.splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if key == "state":
            status["state"] = value
        elif key == "rate":
            try:
                status["rate"] = int(value)
            except ValueError:
                pass
    return status


def read_xruns(dump_json):
    """Map node.name -> xrun-count from `pw-dump` output."""
    counts = {}
    try:
        objects = json.loads(dump_json)
    except json.JSONDecodeError:
        return counts
    for obj in objects:
        info = obj.get("info") or {}
        props = info.get("props") or {}
        name = props.get("node.name")
        if name is None:
            continue
        xruns = info.get("xrun-count")
        if xruns is None:
            continue
        counts[name] = xruns
    return counts


def diff_xruns(prev, cur):
    """Return only nodes whose xrun count increased."""
    deltas = {}
    for name, count in cur.items():
        before = prev.get(name, 0)
        if count > before:
            deltas[name] = count - before
    return deltas


def format_report(rate, deltas):
    rate_text = f"rate={rate}" if rate else "rate=unknown"
    if not deltas:
        return f"{rate_text} clean (no xruns)"
    detail = " ".join(f"{name}={count}" for name, count in sorted(deltas.items()))
    return f"{rate_text} XRUNS {detail}"


def _current_rate():
    for path in glob.glob("/proc/asound/card*/pcm*/sub*/status"):
        try:
            with open(path) as handle:
                status = parse_alsa_status(handle.read())
        except OSError:
            continue
        if status["state"] == "RUNNING" and status["rate"]:
            return status["rate"]
    return None


def run(interval=5, runner=subprocess.run):
    """Poll xrun counters forever, logging deltas with rate context."""
    prev = {}
    while True:
        result = runner(["pw-dump"], capture_output=True, text=True)
        cur = read_xruns(result.stdout)
        deltas = diff_xruns(prev, cur)
        if deltas:
            logging.warning(format_report(_current_rate(), deltas))
        prev = cur
        time.sleep(interval)
