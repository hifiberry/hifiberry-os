"""Glitch instrumentation for USB gadget audio.

An xrun count with no sample rate attached is not actionable -- the whole point
is to learn which rates hold and which fall apart, so every report carries the
negotiated rate. And a report with no correctly-attributed *card* is worse
than useless: the target has both a HiFiBerry DAC card and the USB gadget
card, and a gadget xrun mis-attributed to the DAC's rate (or vice versa)
would invalidate the whole experiment silently. So attribution here is
explicit and auditable rather than guessed -- every rate lookup says which
card it came from, and genuine ambiguity (more than one card RUNNING at
different rates) is surfaced, not silently resolved by picking the first.
"""

import glob
import json
import logging
import os
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
    """Map node.name -> xrun-count from `pw-dump` output.

    Returns None if dump_json could not be parsed at all -- e.g. pw-dump
    crashed or emitted partial/garbage output. That is an instrumentation
    failure and must never be conflated with a genuine clean reading
    ({}), which is what a well-formed dump with no matching nodes yields.
    """
    try:
        objects = json.loads(dump_json)
    except json.JSONDecodeError:
        return None
    counts = {}
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
    """Return xrun deltas for nodes that gained xruns since `prev`.

    A count that increased is reported as the plain delta. A count that
    *decreased* means the node's counter reset (e.g. the node restarted),
    not that xruns were un-counted -- at minimum `cur` xruns have occurred
    since the reset, so that is what gets reported (when non-zero). A
    reset straight to zero has nothing to report yet.
    """
    deltas = {}
    for name, count in cur.items():
        before = prev.get(name, 0)
        if count > before:
            deltas[name] = count - before
        elif count < before:
            if count:
                deltas[name] = count
    return deltas


def format_report(rate, deltas, card=None):
    rate_text = f"rate={rate}" if rate else "rate=unknown"
    if card:
        rate_text = f"{rate_text} card={card}"
    if not deltas:
        return f"{rate_text} clean (no xruns)"
    detail = " ".join(f"{name}={count}" for name, count in sorted(deltas.items()))
    return f"{rate_text} XRUNS {detail}"


def _card_identity(card_dir, base_dir):
    """Human-auditable identity for a card directory.

    Prefers the card's own /proc/asound/<card>/id name (e.g. "gadget")
    alongside the directory name, so a log reader can tell exactly which
    card a rate came from without cross-referencing anything else.
    """
    id_path = os.path.join(base_dir, card_dir, "id")
    try:
        with open(id_path) as handle:
            name = handle.read().strip()
    except OSError:
        name = None
    return f"{card_dir}:{name}" if name else card_dir


def _current_rate(card_filter=None, base_dir="/proc/asound"):
    """Find the negotiated rate of the RUNNING substream(s) under base_dir.

    Returns (card_identity, rate).

    - No card RUNNING: (None, None).
    - Exactly one card RUNNING (or several agreeing on one rate): that
      card's identity and rate.
    - Several cards RUNNING at *different* rates: attribution is
      genuinely ambiguous. Rather than silently picking the first one in
      glob order (the historical bug -- and the exact failure that would
      invalidate this experiment), the identity names every card/rate
      involved and rate is None, so the ambiguity is visible in the log.

    `card_filter`, if given, restricts the scan to cards whose directory
    name (e.g. "card1") or id (e.g. "gadget") contains it as a substring.
    Unset, it scans every card -- the historical default behavior. The
    USB gadget's real card name isn't known until it's bound on hardware,
    so nothing here hardcodes a guess at it; callers can pass it once
    they know it.
    """
    running = []
    pattern = os.path.join(base_dir, "card*", "pcm*", "sub*", "status")
    for path in sorted(glob.glob(pattern)):
        rel = os.path.relpath(path, base_dir)
        card_dir = rel.split(os.sep)[0]
        identity = _card_identity(card_dir, base_dir)
        if card_filter and card_filter not in card_dir and card_filter not in identity:
            continue
        try:
            with open(path) as handle:
                status = parse_alsa_status(handle.read())
        except OSError:
            continue
        if status["state"] == "RUNNING" and status["rate"]:
            running.append((identity, status["rate"]))

    if not running:
        return None, None

    distinct_rates = {rate for _, rate in running}
    if len(distinct_rates) > 1:
        summary = ", ".join(f"{card}={rate}" for card, rate in running)
        return f"AMBIGUOUS({summary})", None

    return running[0]


def run(interval=5, runner=subprocess.run, sleeper=time.sleep, card_filter=None,
        base_dir="/proc/asound"):
    """Poll xrun counters forever, logging deltas with rate+card context.

    `runner` is called once per poll like subprocess.run(["pw-dump"], ...)
    and must return an object with a `.stdout` attribute holding the dump
    JSON. It may raise StopIteration to end the loop -- real callers never
    do this; it exists so tests can bound an otherwise-infinite loop.
    """
    prev = None
    while True:
        try:
            result = runner(["pw-dump"], capture_output=True, text=True)
        except StopIteration:
            return
        cur = read_xruns(result.stdout)
        if cur is None:
            # Instrumentation failure: pw-dump's output didn't parse. This
            # must read as clearly different from a clean poll -- reporting
            # "clean" here would hide the fact that we have no idea what
            # happened during this interval.
            logging.warning(
                "xrun read FAILED: pw-dump output did not parse as JSON -- "
                "xrun state for this poll is UNKNOWN, not clean"
            )
        elif prev is None:
            # First poll: prime the baseline only. Diffing against {} here
            # would treat every xrun a node already carried before we
            # started watching as a fresh glitch happening right now.
            prev = cur
        else:
            deltas = diff_xruns(prev, cur)
            if deltas:
                card, rate = _current_rate(card_filter=card_filter, base_dir=base_dir)
                logging.warning(format_report(rate, deltas, card=card))
            prev = cur
        sleeper(interval)
