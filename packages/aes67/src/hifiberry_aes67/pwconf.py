"""Generate the PipeWire drop-in that loads module-rtp-sap.

Written into the *user* PipeWire config directory rather than /etc, for two
reasons. The agent runs as a user service and cannot write /etc; and the latency
lives inside the module's argument block, so it cannot be overridden by a second
drop-in -- PipeWire appends `context.modules` rather than merging it, and a
second file would load a second rtp-sap module instead of changing the first.
Generating the single file we own sidesteps both problems and needs no root.

The package therefore ships no /etc/pipewire drop-in. If an older version
installed one, it must be removed or two modules will load.
"""

import logging
import os

TEMPLATE = """\
# AES67 receive support for HiFiBerryOS -- GENERATED FILE, DO NOT EDIT.
#
# Written by hifiberry-aes67 from the board default and any latency override
# set in the web UI. Hand edits are lost whenever the agent regenerates it;
# change the latency through Services > AES67, or with
# `hifiberry-aes67 set-latency`.
#
# Loaded into the main PipeWire daemon deliberately: a second daemon only gets
# RT scheduling if it is launched with it, and without RT it produces xruns
# that no amount of buffering fixes.
#
# Each SAP-announced stream becomes an Audio/Source node. Those nodes are inert
# until something links to them -- no multicast join, no CPU -- so discovering
# every stream on the network is free.
context.modules = [
    {{ name = libpipewire-module-rtp-sap
        args = {{
            # AES67 over Wi-Fi is not viable. Keep this on wired ethernet.
            local.ifname = {interface}
            sap.ip = 239.255.255.255
            sap.port = 9875
            net.ttl = 32
            net.loop = false
            stream.rules = [
                {{
                    matches = [ {{ rtp.session = "~.*" }} ]
                    actions = {{
                        create-stream = {{
                            node.virtual = false
                            media.class = "Audio/Source"
                            device.api = aes67
                            sess.latency.msec = {latency}
                        }}
                    }}
                }}
            ]
        }}
    }}
]
"""

# Older packages shipped this as a system conffile. Two drop-ins would load two
# rtp-sap modules, so the agent removes it if it can.
LEGACY_SYSTEM_PATH = "/etc/pipewire/pipewire.conf.d/60-hifiberry-aes67.conf"


def default_path():
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return os.path.join(base, "pipewire", "pipewire.conf.d",
                        "60-hifiberry-aes67.conf")


def render(latency_msec, interface="eth0"):
    return TEMPLATE.format(latency=int(latency_msec), interface=interface)


def write(path, latency_msec, interface="eth0"):
    """Write the drop-in. Returns True if the content changed.

    The caller uses the return value to decide whether to restart PipeWire,
    which interrupts playback and must not happen on every agent start.
    """
    path = path or default_path()
    desired = render(latency_msec, interface)
    try:
        with open(path) as handle:
            if handle.read() == desired:
                return False
    except (FileNotFoundError, OSError):
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as handle:
        handle.write(desired)
    os.replace(tmp, path)
    logging.info("wrote %s (latency %s ms, interface %s)", path, latency_msec,
                 interface)
    return True


def legacy_system_dropin_present(path=LEGACY_SYSTEM_PATH):
    return os.path.exists(path)
