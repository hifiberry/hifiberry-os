#!/usr/bin/env python3
"""CLI for the HiFiBerry AES67 receiver."""

import argparse
import json
import logging
import threading

from . import api, configure, linker, pwgraph, registry, selection, state


def build_parser():
    parser = argparse.ArgumentParser(
        description="Receive AES67 audio from a Dante network"
    )
    parser.add_argument(
        "action",
        choices=("connect", "disconnect", "streams", "select", "serve", "state",
                 "set-latency", "settings"),
    )
    parser.add_argument("--stream", default=None,
                        help="session name for 'select'; omit to clear the selection")
    parser.add_argument("--latency", default=None,
                        help="milliseconds for 'set-latency'; "
                             "'default' restores the board default")
    parser.add_argument("--interface", default=api.DEFAULT_INTERFACE,
                        help="network interface for AES67 (default: eth0)")
    parser.add_argument("--watch", action="store_true",
                        help="with 'connect', keep reconciling the link")
    parser.add_argument("--port", type=int, default=api.DEFAULT_PORT,
                        help="REST API port (default: 1083)")
    parser.add_argument("--acr-port", type=int, default=state.DEFAULT_ACR_PORT,
                        help="audiocontrol port (default: 1080)")
    parser.add_argument("--interval", type=int, default=5,
                        help="reconcile/state poll interval in seconds")
    parser.add_argument("--no-state", action="store_true",
                        help="with 'serve', do not also report state to audiocontrol")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser


def dispatch(args, deps=None):
    deps = deps or {}
    dump = deps.get("dump", pwgraph.dump)
    list_streams = deps.get("streams", registry.streams)
    set_selection = deps.get("set_selection", selection.set)

    if args.action == "connect":
        if args.watch:
            return linker.watch(interval=args.interval)
        return linker.connect()
    if args.action == "disconnect":
        return linker.disconnect()
    if args.action == "streams":
        print(json.dumps(list_streams(dump()), indent=2))
        return 0
    if args.action == "select":
        set_selection(args.stream)
        return 0
    if args.action == "state":
        return state.run(interval=args.interval, port=args.acr_port)
    if args.action == "settings":
        print(json.dumps(deps.get("current", configure.current)(), indent=2))
        return 0
    if args.action == "set-latency":
        raw = args.latency
        value = None if raw in (None, "default") else int(raw)
        applier = deps.get("apply_latency", configure.apply_latency)
        print(json.dumps(applier(value, interface=args.interface), indent=2))
        return 0

    # 'serve' is the agent: the REST API plus, unless suppressed, the ACR state
    # reporter. They share a process so the package needs two units rather than
    # three -- the API must stay up while the aes67.service toggle is off, and
    # so must state reporting.
    if not args.no_state:
        reporter = deps.get("state_run", state.run)
        threading.Thread(
            target=reporter,
            kwargs={"interval": args.interval, "port": args.acr_port},
            daemon=True,
            name="aes67-state",
        ).start()
    # Make the PipeWire drop-in match the stored settings before serving.
    # ensure() restarts PipeWire only when the rendered config actually
    # changed, so a normal agent start does not interrupt playback.
    deps.get("ensure", configure.ensure)(interface=args.interface)
    serve = deps.get("serve", api.serve)
    serve(port=args.port, interface=args.interface)
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
