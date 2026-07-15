#!/usr/bin/env python3
"""CLI for creating/removing the UAC2 gadget (root only)."""

import argparse
import logging
import sys

from . import gadget


def main():
    parser = argparse.ArgumentParser(description="Create or remove the HiFiBerry UAC2 USB gadget")
    parser.add_argument("action", choices=("create", "remove"))
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    try:
        if args.action == "create":
            gadget.create_gadget()
        else:
            gadget.remove_gadget()
    except gadget.NoUDCError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
    raise SystemExit(0)


if __name__ == "__main__":
    main()
