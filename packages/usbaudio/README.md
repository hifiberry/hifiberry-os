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

This flag requires **hifiberry-configurator >= 2.13.19** (see
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
`override_dh_installsystemd`):

- **`hifiberry-usbgadget.service`** (system unit) creates the UAC2 gadget.
  It is foundational infrastructure, not a WebUI-toggleable player, so it is
  enabled and started unconditionally. Its
  `ConditionPathExistsGlob=/sys/class/udc/*` makes this a safe no-op when
  USB device mode was never enabled (see Prerequisites above) -- the unit
  simply skips instead of failing.
- **`usbaudio-state.service`** (user unit) reports state to ACR. It is
  *not* surfaced as a WebUI player toggle -- `players.d/usbaudio.json`
  names only `usbaudio` -- so nothing else would ever enable it. It is
  therefore enabled and started unconditionally too.
- **`usbaudio.service`** (user unit) links the gadget's audio to the DAC. It
  is the WebUI-toggleable player, like every other HiFiBerryOS player
  (sendspin, librespot, shairport, ...): it ships **disabled**, and the
  user turns it on from *Services > Players*. Its systemd permissions are
  granted to config-server via `/etc/configserver/conf.d/usbaudio.json`.

## `--card` must be pinned during hardware bring-up

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
ExecStart=/usr/bin/hifiberry-usbaudio state --card PLACEHOLDER_PIN_DURING_BRINGUP
```

`PLACEHOLDER_PIN_DURING_BRINGUP` is a deliberately-invalid value: it
matches no real card, so out of the box this unit just always reports
"stopped" (harmless) rather than crash-looping. **Once the gadget's real
`/proc/asound` card name/id is confirmed on hardware** (bind the gadget,
then check `cat /proc/asound/card*/id`), replace the placeholder with that
value in the unit file. The same applies to `linker.py`'s
`GADGET_NODE_PREFIX`, which is an unverified placeholder for the PipeWire
node name until confirmed the same way.

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
