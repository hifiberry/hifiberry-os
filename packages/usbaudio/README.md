# hifiberry-usbaudio

> **Experimental.** Not published to the HiFiBerry package repository and not
> part of any HiFiBerryOS install. It is kept here so the work is not lost and
> can be picked up again; expect rough edges and interface changes, and do not
> rely on it in a working setup.

Presents the HiFiBerry device to a host computer (Mac, PC, ...) as a
class-compliant **UAC2 USB sound card** ("USB gadget mode"), and routes the
audio the host sends over USB to the HiFiBerry DAC using PipeWire. It also
reports play/stop state to [audiocontrol](https://github.com/hifiberry/acr)
(ACR) so the HiFiBerryOS Web UI shows whether the host is currently
streaming.

## Prerequisites: USB device mode

The Pi's USB controller must be switched from host mode (the default, used
for USB keyboards/mice/storage) to **device mode** before a gadget can ever
be bound:

```sh
sudo config-configtxt --enable-usb-gadget
sudo reboot
```

This flag requires **hifiberry-configurator >= 2.13.20** (see
`debian/control`). Without it, `/sys/class/udc` has no entries and
`hifiberry-usbgadget.service` cleanly no-ops (see below) instead of failing.

## Components

| Module | Responsibility |
|--------|----------------|
| `gadget.py` / `hifiberry-usbgadget` CLI | Creates/removes the UAC2 gadget via configfs |
| `linker.py` | `pw-link`s the gadget's capture node to the DAC's playback sink |
| `monitor.py` | Logs xrun/rate glitches, card-scoped, for bring-up diagnostics |
| `state.py` | Polls ALSA substream state and POSTs play/stop to ACR |
| `main.py` / `hifiberry-usbaudio` CLI | `connect` / `disconnect` / `monitor` / `state` |

## systemd units and why they are enabled differently

This package ships three units, and they are **deliberately not all
enabled/started the same way** (see `debian/rules`,
`override_dh_installsystemd` / `override_dh_installsystemduser`).
`hifiberry-usbgadget.service` is a *system* unit, handled by
`dh_installsystemd`; the other two are *user* units
(`/usr/lib/systemd/user`), handled by the separate `dh_installsystemduser`
helper -- naming a user unit to `dh_installsystemd` makes it fail the build
with "does not install unit ...", since that helper only looks at system
units.

- **`hifiberry-usbgadget.service`** (system unit) creates the UAC2 gadget.
  It is foundational infrastructure, not a WebUI-toggleable player, so it is
  enabled and started unconditionally. Its
  `ConditionPathExistsGlob=/sys/class/udc/*` makes this a safe no-op when
  USB device mode was never enabled (see Prerequisites above) -- the unit
  simply skips instead of failing.
- **`usbaudio-state.service`** (user unit) reports state to ACR. It is
  *not* surfaced as a WebUI player toggle -- `players.d/usbaudio.json`
  names only `usbaudio` -- so nothing else would ever enable it on its
  behalf. It used to ship **disabled** because its `ExecStart` carried a
  deliberately-invalid `PLACEHOLDER_PIN_DURING_BRINGUP` card, and
  `state.run()` raises without a valid `--card`; auto-enabling it while
  that placeholder was in place would have meant a permanently-failed
  systemd unit on every install/boot. Hardware bring-up has since pinned
  `--card UAC2Gadget` (see below) -- the ALSA card id the UAC2 gadget
  driver assigns itself, independent of SoC, so it holds on every Pi that
  supports gadget mode -- so this unit now ships **enabled**, the same as
  `hifiberry-usbgadget.service`. When the gadget isn't bound (no card named
  `UAC2Gadget` exists) it degrades safely: `discover_status_paths` simply
  finds nothing to scope to and the service reports "stopped".
- **`usbaudio.service`** (user unit) links the gadget's audio to the DAC. It
  is the WebUI-toggleable player, like every other HiFiBerryOS player
  (sendspin, librespot, shairport, ...): it ships **disabled**, and the
  user turns it on from *Services > Players*. Its systemd permissions are
  granted to config-server via `/etc/configserver/conf.d/usbaudio.json`.

## `--card` and `GADGET_NODE_PREFIX`, pinned from hardware bring-up

`hifiberry-usbaudio state` (and `monitor`) scope every `/proc/asound` read
to a single card via `--card <name-or-id>`. This matters because the
device has **two** ALSA cards once the gadget is bound: the HiFiBerry DAC's
own card, and the USB gadget's card. Without scoping, the DAC's own local
playback (e.g. Spotify through the DAC) gets misreported to ACR as the USB
gadget playing.

Because of this, **`state.run()` refuses to start at all without an
explicit `--card`** -- a misconfigured/un-pinned unit fails loudly
(`ValueError`, visible in `journalctl --user -u usbaudio-state`) rather than
silently reporting plausible-looking nonsense.

The shipped `systemd/usbaudio-state.service` ships with

```
ExecStart=/usr/bin/hifiberry-usbaudio state --card UAC2Gadget
```

`UAC2Gadget` is the real ALSA card id the UAC2 gadget driver assigns
itself, confirmed on a CM5 via `/proc/asound/cards`
(`1 [UAC2Gadget     ]: UAC2_Gadget - UAC2_Gadget`). It is matched by
`monitor.discover_status_paths`'s `card_filter` against the card's
*identity* string (`"<card_dir>:<id>"`, built from
`/proc/asound/<card_dir>/id`), not the bare directory name (`card1`) --
so `UAC2Gadget` matches because it's the id, not because of anything
about which card number the kernel happened to assign. Since the gadget
driver assigns this id itself, independent of the SoC/platform device, it
is expected to be the same value on every Pi that supports gadget mode
(Pi 4/CM4, CM5, ...), not just the CM5 it was confirmed on -- unlike
`GADGET_NODE_PREFIX` below. Because the value is valid,
`usbaudio-state.service` now ships **enabled** (see above).

`linker.py`'s `GADGET_NODE_PREFIX` is pinned the same way but does **not**
carry the same board-portability guarantee. Measured on a CM5 with the
gadget bound, `pw-cli ls Node` reported the gadget's capture node as
`alsa_input.platform-1000480000.usb.stereo-fallback`, where
`1000480000.usb` is the dwc2 USB controller's platform-device address on
CM5/Pi 5 specifically -- Pi 4/CM4 exposes the same controller at
`7e980000.usb` instead. `GADGET_NODE_PREFIX` is therefore pinned to
`"alsa_input.platform-1000480000.usb."`, which is **CM5-only**: it will not
match on Pi 4/CM4 (`connect()` will log "USB gadget audio node not found"
there). A more generic prefix (e.g. just `"alsa_input.platform-"`) was
considered and rejected -- it would also match
`alsa_input.platform-soc_107c000000_sound.stereo-fallback`, the DAC's own
ADC node, and linking that into the DAC's own sink is a feedback loop, not
USB audio. `find_node_by_prefix` only does a plain `startswith` match, and
the varying controller address sits in the middle of the node name, so a
single prefix cannot be both specific enough to exclude the DAC's ADC and
generic enough to cover every board. **Pi 4/CM4 gadget-mode bring-up is
still open work**: either add board detection (e.g. read the bound UDC
name from `/sys/class/udc`, as `gadget.find_udc()` already does, and build
the prefix from that at runtime) or extend the match past a plain prefix.

## HiFiBerryOS integration files

- `/usr/lib/systemd/system/hifiberry-usbgadget.service` -- creates the gadget
- `/usr/lib/systemd/user/usbaudio.service` -- links gadget audio to the DAC
- `/usr/lib/systemd/user/usbaudio-state.service` -- reports state to ACR
- `/etc/hifiberry/players.d/usbaudio.json` -- Web UI player descriptor
- `/etc/hifiberry/players.d/icons/usbaudio.svg` -- Web UI icon
- `/etc/configserver/conf.d/usbaudio.json` -- grants the Web UI control of `usbaudio.service`
- `/etc/audiocontrol/players.d/usbaudio.json` -- registers the `usbaudio` ACR
  generic player (`capabilities: ["play", "stop"]` -- the gadget can only
  ever report play/stop; it has no seek, skip, playlist, or remote-command
  support, since the host -- not ACR -- drives playback)

`debian/postinst` restarts `config-server` (when already running) after
install, since config-server caches the `conf.d` systemd-permission
drop-ins at startup and otherwise wouldn't know it may control `usbaudio`
until its next restart.

## Manual usage

```sh
# Gadget lifecycle (root; normally systemd-managed)
sudo hifiberry-usbgadget create
sudo hifiberry-usbgadget remove

# Audio routing (normally systemd-managed as a user service)
hifiberry-usbaudio connect
hifiberry-usbaudio disconnect

# Diagnostics / state reporting (card-scoped once pinned, see above)
hifiberry-usbaudio monitor --card gadget
hifiberry-usbaudio state --card gadget
```

## Building

```sh
./build.sh                 # wraps dpkg-buildpackage -us -uc -b
```

Tests (Python standard library only, no external deps):

```sh
cd src
python3 -m pytest tests/ -v
```
