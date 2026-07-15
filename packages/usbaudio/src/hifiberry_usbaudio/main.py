#!/usr/bin/env python3
"""CLI for HiFiBerry USB audio input."""

import argparse
import logging

from . import linker, monitor, state


def build_parser():
    parser = argparse.ArgumentParser(
        description="Connect the UAC2 USB gadget audio input to the HiFiBerry DAC"
    )
    parser.add_argument("action", choices=("connect", "disconnect", "monitor", "state"))
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument(
        "--interval", type=int, default=5, help="monitor/state poll interval (s)"
    )
    parser.add_argument("--card", type=str, default=None, help="filter by card name or id")
    parser.add_argument(
        "--port", type=int, default=1080, help="ACR port for state reporting (default: 1080)"
    )
    return parser


def dispatch(args):
    if args.action == "connect":
        return linker.connect()
    if args.action == "disconnect":
        return linker.disconnect()
    if args.action == "state":
        # state.run() accepts card_filter parameter
        state.run(interval=args.interval, card_filter=args.card, port=args.port)
        return 0
    # monitor.run() accepts card_filter parameter
    monitor.run(interval=args.interval, card_filter=args.card)
    return 0


def main():
    args = build_parser().parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )
    raise SystemExit(dispatch(args))


if __name__ == "__main__":
    main()
