# hifiberry-usbaudio

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

### CM5 IO board: leave the `USB_OTG` jumper unfitted

The CM5 IO board has a `USB_OTG` jumper wired to the SoC's `OTG_ID` pin --
a Raspberry Pi engineer confirms this wiring in [a forum
post](https://forums.raspberrypi.com/viewtopic.php?t=380836), and says it
selects host vs. device role.

Measured on a CM5 Lite / CM5 IO board today: fitting the jumper is **not**
required for gadget mode, and it actively breaks booting -- with it fitted
the board did not boot correctly. With the jumper **removed**, gadget mode
works fully end to end: the UDC reports `configured` at high-speed and the
host (a Mac) enumerates `HiFiBerry USB Audio`.

**Leave `USB_OTG` unfitted.** The exact boot failure mode with the jumper
fitted was not characterised -- the likely mechanism is that grounding
`OTG_ID` puts the module into rpiboot / USB-boot-wait before it falls
through to local media, but this is an unconfirmed guess, not a measured
root cause.

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

## Verified hardware configuration

Confirmed working end to end on: CM5 Lite on a CM5 IO board, USB-C to the
host computer, with the Pi **powered from that same USB-C** connection.
`USB_OTG` jumper **not fitted** (see above).

- `config-configtxt --enable-usb-gadget` + reboot results in
  `/sys/class/udc/` containing `1000480000.usb`; `config.txt`'s `[cm5]`
  section gets `dtoverlay=dwc2,dr_mode=peripheral`; `PSU_MAX_CURRENT=3000`
  is applied to the bootloader EEPROM automatically as part of enabling the
  gadget.
- The gadget shows up as ALSA `card 1: UAC2Gadget [UAC2_Gadget]`, and
  PipeWire exposes its capture node as
  `alsa_input.platform-1000480000.usb.stereo-fallback` (see
  `GADGET_NODE_PREFIX` above).
- The host (Mac) sees **both** directions of the gadget -- an output
  (`out=2`) and an input (`in=2`) -- at USB high-speed (480 Mb/s).
- `hifiberry-usbaudio connect` links the gadget's `capture_FL/FR` straight
  to the DAC sink's `alsa_output.platform-soc_107c000000_sound.stereo-fallback:playback_FL/FR`.

## Troubleshooting: UDC reports `not attached`

Symptom: `cat /sys/class/udc/1000480000.usb/state` reports `not attached`
even though the gadget is bound (`function = hifiberry` in the
configfs gadget) and the configuration otherwise looks correct.

Working theory, not a confirmed root cause: dwc2 needs a fresh VBUS
session. If the USB-C cable was already plugged in **before**
`dr_mode=peripheral` took effect (i.e. before the reboot that enables
gadget mode), the session dwc2 sees is stale and no enumeration happens.
What was actually *measured* is that unplugging and re-plugging the
USB-C cable took the state from `not attached` to `configured`, so
re-establishing the physical connection (unplug/replug, or power-cycle it)
is the practical fix, whatever the underlying mechanism turns out to be.

Diagnostic to narrow down where the fault is:

```sh
cat /sys/class/udc/1000480000.usb/state       # not attached | configured
sudo cat /sys/kernel/debug/usb/1000480000.usb/regdump | grep -E "GOTGCTL|DSTS|DCTL"
```

In `GOTGCTL`: bit 19 (`BSESVLD`) means VBUS/session is sensed; bit 16
(`CONID_B`) means the ID pin reports a B-device (peripheral role). In
`DSTS`: bit 0 (`SUSPSTS`) means the bus is suspended. If the session bits
are set but `state` still reads `not attached`, the host isn't enumerating
the device -- check the cable and re-plug it.

## Known issues

- **Pi 4/CM4 gadget-mode bring-up is still open work** -- see the
  `GADGET_NODE_PREFIX` discussion above; the prefix is currently pinned to
  the CM5's dwc2 controller address and won't match on Pi 4/CM4.
- **Full-Speed isochronous descriptors are malformed for 192 kHz.** The
  kernel warns at gadget bind:

  ```
  configfs-gadget.hifiberry gadget.0: FS Playback: Req. wMaxPacketSize 1158 at bInterval 1 > max ISOC 1023, may drop data!
  ```

  Our 192 kHz advertisement (192000 x 2ch x 3 bytes = 1152 bytes/frame)
  exceeds the 1023-byte Full-Speed isochronous packet limit. This is
  harmless in the verified configuration above, since High Speed is what
  actually negotiates there, but the Full-Speed descriptors themselves are
  malformed -- a host that falls back to Full Speed would drop audio. Needs
  fixing (e.g. capping the FS-advertised sample rate/bit depth so the
  packet size fits within 1023 bytes).

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
