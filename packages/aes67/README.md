# hifiberry-aes67

Receives **AES67** audio from a Dante network and plays it through the HiFiBerry
DAC. Streams announced over SAP are discovered automatically, listed over a REST
API, and one can be selected to play.

## What this is, and what it is not

This is a **listening endpoint, not a clock-synchronised AES67 device.** It runs
no PTP daemon, so it does not share the Dante clock; sender and receiver drift at
crystal accuracy and PipeWire's adaptive resampler absorbs it. Measured over 35
minutes this is indistinguishable from local playback (2 source / 1 DAC xrun,
against a no-AES67 control of 1), but it is not suitable for sample-accurate
alignment with other Dante gear.

PTP is not merely omitted for simplicity: on CM5 `eth0` it is unavailable.
Hardware TX timestamping never completes (`timed out while polling for tx
timestamp`, in both master and slave roles) and the interface does not advertise
`software-transmit`, so `ptp4l` cannot synchronise in any mode. Dante also
publishes its AES67 clock on the **ARB timescale**, not TAI, which rules out
disciplining `CLOCK_TAI` from it.

One upside of needing no PTP: AES67 **coexists with AirPlay 2**. A PTP daemon
would collide with `nqptp` over UDP 319/320, as native Dante does.

## Requirements

- **Dante side:** enable AES67 mode on the transmitter in Dante Controller
  (requires a device reboot), then create a **multicast flow** for the channels
  you want. Without a flow there is no SAP announcement and nothing to discover.
- **Network:** multicast needs IGMP snooping **with a querier** on the switch, or
  the stream floods every port.
- **Interface:** wired ethernet. AES67 over Wi-Fi is not viable; `local.ifname`
  in the PipeWire drop-in defaults to `eth0`.
- **PipeWire ≥ 1.1** for `module-rtp-sap`.

## Latency, and why the default depends on the board

The right buffer depth is board-dependent, and this was measured rather than
guessed:

| Board | Default | Evidence |
|---|---|---|
| Pi 5 / CM5 | **3 ms** | 35-min soak matched a no-AES67 control (2 source / 1 DAC xrun) |
| Pi 4 / CM4 | **20 ms** | 3 ms gave **1320 xruns** and audibly choppy playback; 20 ms gave none |
| unknown | 20 ms | conservative — a device that stutters out of the box reads as broken |

Users can override it in *Services → AES67*, or with
`hifiberry-aes67 set-latency --latency 10`. Applying a change regenerates the
PipeWire config and restarts PipeWire, briefly interrupting playback.

## Configuration

There is **no system conffile.** The agent generates
`~/.config/pipewire/pipewire.conf.d/60-hifiberry-aes67.conf` from the board
default plus any override, and restarts PipeWire only when the rendered content
actually changed.

It has to be generated rather than shipped: `sess.latency.msec` lives inside the
module's argument block, and a second drop-in cannot override it — PipeWire
appends `context.modules` rather than merging, so a second file would load a
*second* rtp-sap module. Generating the single file we own solves that, and
doing it in user space means the agent needs no root at all.

The module is loaded into the **main** PipeWire daemon deliberately. A second
daemon only gets RT scheduling if launched with it, and without RT it produces
xruns that no amount of buffering fixes. Do not move it into its own process
without carrying RT priority across.

The selected stream lives in `~/.local/state/hifiberry-aes67/selection.json`, the
latency override in `settings.json` beside it. Both are set through the API,
the web UI, or the CLI.

## systemd units

Both are *user* units, deliberately enabled differently:

- **`aes67-agent.service`** ships **enabled**. It serves the discovery API and
  reports player state to ACR (the state reporter runs on a daemon thread inside
  the same process). The Web UI must be able to list discovered streams while
  AES67 is switched off, so this cannot be what the toggle stops.
- **`aes67.service`** ships **disabled** and is the Web UI toggle, like every
  other HiFiBerryOS player. It runs a reconcile loop so a transmitter that is
  power-cycled, or has AES67 toggled on the Dante side, gets relinked when its
  node returns.

## API

Proxied at `/api/aes67/`, listening on localhost:1083.

| Endpoint | Purpose |
|---|---|
| `GET /api/aes67/v1/streams` | Discovered streams |
| `GET /api/aes67/v1/selection` | Current selection |
| `POST /api/aes67/v1/selection` | Select (`{"stream": "..."}`, or `null` to unroute) |
| `GET /api/aes67/v1/status` | Selection, resolved sink, whether receiving |
| `GET /api/aes67/v1/settings` | Latency, board default, whether overridden, bounds |
| `POST /api/aes67/v1/settings` | Set latency (`{"latency_msec": 10}`, or `null` for the board default) |

The web UI page lives in the separate `hifiberry/hbos-ui` repository
(`src/views/services/aes67.vue`), not in this package.

## Manual usage

```sh
hifiberry-aes67 streams                    # list discovered streams as JSON
hifiberry-aes67 select --stream "AU-U22-f0f33b : 1"
hifiberry-aes67 select                     # clear the selection
hifiberry-aes67 settings                   # show latency and board default
hifiberry-aes67 set-latency --latency 10   # override; 'default' restores board value
hifiberry-aes67 connect                    # link once
hifiberry-aes67 connect --watch            # link and keep reconciling
hifiberry-aes67 disconnect
```

## Known limitation: multicast membership is not released on toggle-off

Streams you never select cost nothing — their PipeWire nodes are inert, with no
IGMP join and no CPU. But once a stream has been routed, PipeWire keeps its
multicast membership even after you toggle AES67 off and the node returns to
`suspended`. `module-rtp-source` joins the group on first activation and holds it
until the node is destroyed, which happens when the SAP announcement expires or
PipeWire restarts.

Practical effect: after toggling off, playback and processing stop, but the
network traffic for that one stream keeps arriving. To stop it fully, remove the
multicast flow in Dante Controller or restart PipeWire. Nothing in this package's
API controls the membership.

## Implementation notes

`pwgraph.py` is the only module that shells out to `pw-dump`; everything else
works on parsed objects, which is why the tests need no PipeWire.

The link target is resolved at runtime from `pw-metadata`'s `default.audio.sink`.
Two hazards this avoids: **`input-processor` must never be the target** — despite
the name it is `/usr/lib/ladspa/riaa.so`, a vinyl RIAA phono EQ curve — and the
ALSA sink name is board-specific (`...iec958-stereo` on a Digi+ versus
`...stereo-fallback` on an analogue DAC), so neither may be hardcoded.

## Building and testing

```sh
./build.sh
cd src && python3 -m pytest tests/ -v      # stdlib only; no PipeWire needed
```
