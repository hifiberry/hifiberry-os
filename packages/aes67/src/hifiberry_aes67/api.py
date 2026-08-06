"""REST API for AES67 stream discovery and selection.

Bound to localhost:1083 and reverse-proxied by nginx at /api/aes67/, which
strips the prefix -- so the paths here are /api/v1/... exactly as the btaudio
service does on 1082.

Routing is kept separate from http.server so it can be tested without binding a
socket.
"""

import json
import logging
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

from . import linker, pwgraph, registry, selection, settings, sink as sinkmod

DEFAULT_PORT = 1083
DEFAULT_INTERFACE = "eth0"


def handle_get(path, objects, selected, target):
    if path == "/api/v1/streams":
        return 200, {"streams": registry.streams(objects)}
    if path == "/api/v1/selection":
        return 200, {"stream": selected}
    if path == "/api/v1/status":
        receiving = bool(
            selected and target and linker.is_linked(objects, selected, target)
        )
        return 200, {
            "stream": selected,
            "sink": target,
            "receiving": receiving,
            "discovered": len(registry.streams(objects)),
        }
    return 404, {"error": "not found"}


def handle_get_settings(latency, board_default, overridden, interface):
    return 200, {
        "latency_msec": latency,
        "board_default_msec": board_default,
        "overridden": overridden,
        "min_msec": settings.MIN_LATENCY_MSEC,
        "max_msec": settings.MAX_LATENCY_MSEC,
        "interface": interface,
    }


def handle_post(path, body, objects, setter):
    if path != "/api/v1/selection":
        return 404, {"error": "not found"}
    name = (body or {}).get("stream")
    if name is not None and not registry.find(objects, name):
        return 400, {"error": f"unknown stream: {name}"}
    setter(name)
    return 200, {"stream": name}


def handle_post_settings(body, apply_latency):
    """Set the receive latency. `apply_latency(value)` persists and applies it.

    A null latency restores the board default -- that is a valid request, not a
    missing field, so absence and null are treated the same.
    """
    value = (body or {}).get("latency_msec")
    if value is not None:
        if isinstance(value, bool) or not isinstance(value, int):
            return 400, {"error": "latency_msec must be an integer or null"}
    try:
        result = apply_latency(value)
    except ValueError as exc:
        return 400, {"error": str(exc)}
    return 200, result


class _Handler(BaseHTTPRequestHandler):
    runner = staticmethod(subprocess.run)
    state_path = None
    interface = DEFAULT_INTERFACE

    def _reply(self, code, payload):
        data = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _context(self):
        objects = pwgraph.dump(runner=self.runner)
        selected = selection.get(self.state_path)
        target = sinkmod.default_sink(objects, runner=self.runner)
        return objects, selected, target

    def do_GET(self):  # noqa: N802 - http.server API
        if self.path == "/api/v1/settings":
            from . import configure
            state = configure.current()
            self._reply(*handle_get_settings(
                state["latency_msec"], state["board_default_msec"],
                state["overridden"], self.interface))
            return
        objects, selected, target = self._context()
        self._reply(*handle_get(self.path, objects, selected, target))

    def do_POST(self):  # noqa: N802 - http.server API
        length = int(self.headers.get("Content-Length") or 0)
        try:
            body = json.loads(self.rfile.read(length) or b"{}")
        except ValueError:
            self._reply(400, {"error": "invalid JSON"})
            return
        if self.path == "/api/v1/settings":
            from . import configure
            iface = self.interface
            self._reply(*handle_post_settings(
                body,
                apply_latency=lambda v: configure.apply_latency(
                    v, interface=iface),
            ))
            return
        objects, _, _ = self._context()
        code, payload = handle_post(
            self.path, body, objects,
            setter=lambda name: selection.set(name, self.state_path),
        )
        self._reply(code, payload)

    def log_message(self, fmt, *args):
        logging.debug("api: " + fmt, *args)


def serve(port=DEFAULT_PORT, path=None, interface=DEFAULT_INTERFACE):
    _Handler.state_path = path
    _Handler.interface = interface
    server = HTTPServer(("127.0.0.1", port), _Handler)
    logging.info("AES67 API listening on 127.0.0.1:%s", port)
    server.serve_forever()
