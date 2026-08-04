"""Turn the PipeWire graph into the list of discovered AES67 streams.

module-rtp-sap creates one Audio/Source node per SAP announcement. Those nodes
are inert until something links to them -- no multicast join, no CPU -- so
listing every announced stream costs nothing.
"""

from . import pwgraph


def _source_ip(origin):
    # SDP o= line, e.g. "- 758697 758697 IN IP4 192.168.1.157"
    parts = (origin or "").split()
    if len(parts) >= 6 and parts[3] == "IN" and parts[4] in ("IP4", "IP6"):
        return parts[5]
    return None


def _as_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def streams(objects):
    found = []
    for node in pwgraph.nodes(objects):
        p = pwgraph.props(node)
        if p.get("device.api") != "aes67":
            continue
        # Receive only: ignore any AES67 sink that happens to exist.
        if p.get("media.class") != "Audio/Source":
            continue
        found.append({
            "name": p.get("node.name"),
            "channels": _as_int(p.get("rtp.channels")),
            "rate": _as_int(p.get("rtp.rate")),
            "format": p.get("rtp.mime"),
            "address": p.get("rtp.destination.ip"),
            "port": _as_int(p.get("rtp.destination.port")),
            "source_ip": _source_ip(p.get("rtp.origin")),
            "node_id": node.get("id"),
        })
    return found


def find(objects, name):
    for stream in streams(objects):
        if stream["name"] == name:
            return stream
    return None
