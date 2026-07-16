# hifiberry-usbaudio — development status

**Status: PAUSED (2026-07-16).** The feature works end to end at the USB and
PipeWire layers on a CM5, but development is on hold. This file is the
resume point: what exists, what was actually verified on hardware, and what
is still open. See `README.md` for how the pieces work.

## Where the code lives

- **`packages/usbaudio/`** — this package (new). Branch
  `feature/usb-audio-gadget` in the outer repo. **Not merged, not pushed,
  not published.**
- **`packages/pipewire-configs/`** — one added file,
  `10-hifiberry-rates.conf` (allow 44.1–192 kHz instead of pinning 48 kHz),
  version 1.0.9. Same branch. Fleet-wide change (affects every HiFiBerryOS
  device), already agreed.
- **`packages/configurator/`** (nested repo, remote
  `github.com/hifiberry/configurator`) — branch `feature/usb-gadget-config`,
  version **2.13.20**. Adds the `--enable-usb-gadget` / `--disable-usb-gadget`
  CLI, model-aware `config.txt` editing, the Pi-model USB-gadget capability
  table, and `PSU_MAX_CURRENT` bootloader-EEPROM handling. Considered good;
  **not merged, not pushed.** (2.13.19 was skipped: the public repo already
  ships a *different* 2.13.19 without this work — do not reuse that version.)

## Built debs (on build host 192.168.1.112, NOT published)

- `~/hifiberry-configurator_2.13.20_all.deb` — verified to actually contain
  the gadget code (built from local source via the configurator repo's own
  `build-deb.sh`; the package's outer `build.sh` clones from GitHub and would
  silently build stock — do not use it for this branch).
- `~/hifiberry-os/packages/usbaudio/hifiberry-usbaudio_0.1.0_all.deb` — 80
  tests pass inside the build chroot. Note: needs `python3-pytest` in
  Build-Depends (already added) because the build runs the suite.
- `pipewire-configs` 1.0.9 — **not built** (config-only, trivial when needed).

## Verified on hardware ✅

On a **CM5 Lite / CM5 IO board**, USB-C to a Mac, Pi powered from that USB-C,
`USB_OTG` jumper **not** fitted, with a **DAC2 ADC Pro** HAT attached:

- `config-configtxt --enable-usb-gadget` correctly detected `Pi Version: CM5`
  (distinct from Pi 5), wrote `dtoverlay=dwc2,dr_mode=peripheral` into the
  `[cm5]` section (not `[all]`), and auto-applied `PSU_MAX_CURRENT=3000` to
  the bootloader EEPROM.
- After reboot: `/sys/class/udc/` = `1000480000.usb`; `hifiberry-usbgadget`
  bound the UAC2 gadget automatically; ALSA `card 1: UAC2Gadget`; PipeWire
  node `alsa_input.platform-1000480000.usb.stereo-fallback`.
- The Mac enumerated it at USB high-speed (480 Mb/s), showing **both**
  directions (output 2ch + input 2ch) — `iProduct` is `HiFiBerry USB Audio`.
- `hifiberry-usbaudio connect` linked the gadget's `capture_FL/FR` straight
  into the DAC sink (`alsa_output.platform-soc_107c000000_sound...`),
  bypassing the RIAA `input-processor` as intended. Links confirmed present
  via `pw-link -l`.
- Gadget teardown/recreate (`hifiberry-usbgadget remove` → `create`) works
  cleanly on real hardware (the idempotency/teardown fixes hold up).
- The `not attached` → `configured` recovery (unplug/replug the USB-C) was
  reproduced; documented in `README.md`.

## NOT yet verified / not done ❌

- **Actual audible output.** The audio path was linked in the graph, but that
  the Mac's audio is *heard from the DAC's speakers* was never confirmed by a
  human. This is the first thing to check on resume.
- **192 kHz viability.** The whole reason `monitor.py` exists. The rate sweep
  (44.1 / 48 / 96 / 192 kHz, counting xruns per rate) was never run. Whether
  dwc2 sustains 192 kHz isochronous is still an open question.
- **ACR / WebUI integration at runtime.** `usbaudio-state.service` and the
  `players.d` registration are shipped and unit-tested, but were never
  exercised against a live ACR (does the WebUI show play/stop, does the
  toggle start/stop the player).
- **Pi 4 / CM4.** `GADGET_NODE_PREFIX` is pinned to the CM5 dwc2 address
  (`1000480000.usb`) and will not match on Pi 4/CM4 (`7e980000.usb`). The
  config layer is already model-aware; only node matching is CM5-only. See
  README "known issues" for the two fix options.

## Known issues to fix (details in README.md)

1. **Full-Speed descriptors malformed for 192 kHz** — `wMaxPacketSize 1158 >
   max ISOC 1023`. Harmless at High Speed (what negotiates), but a FS
   fallback would drop audio. Cap the FS-advertised rate/depth.
2. **Pi 4/CM4 node matching** — make `GADGET_NODE_PREFIX` board-aware (e.g.
   derive it from the bound UDC name) or match on node properties instead of
   a plain string prefix.
3. **macOS shows the device as "Playback Inactive" / "Capture Inactive"**,
   not "HiFiBerry". Confirmed a **kernel limitation**: macOS names USB audio
   by the AudioStreaming alt-0 interface string, which is hardcoded in
   `f_uac2.c` and not exposed via configfs (every configfs naming knob was
   set to sentinels and macOS ignored all of them; `iProduct` *is* correct).
   Fixing means patching the kernel `f_uac2` — decide deliberately. Other
   hosts (Linux/Windows) may already show `HiFiBerry USB Audio`; check before
   investing.

## Current state of the test device (hbosdev, 192.168.1.195)

**The gadget is currently DISABLED on this box.** As of 2026-07-16 hbosdev
was repurposed: the DAC2 ADC Pro was swapped for a **HiFiBerry Digi+**, and
USB gadget mode was turned off (`config-configtxt --disable-usb-gadget` →
`dr_mode=host`; the user gadget/state units disabled). To resume USB gadget
work on this device you must re-enable it (`--enable-usb-gadget` + reboot)
and, ideally, power the CM5IO from its **barrel jack** rather than the Mac —
the Pi browned out and dropped off the network during an `apt update` while
powered solely from the Mac's USB-C (only 250 mA was allocated on that port),
so barrel-jack power is the more reliable arrangement and makes the USB-C a
pure data link.

## Loose ends outside this package

- Off-scope commit `6a2e535d` (build.sh conflict-abort changes for
  acr/dspprofiles/roomeq) is sitting on the `feature/usb-audio-gadget`
  branch — it was committed there by mistake. Decide: cherry-pick to its own
  branch, or drop. Looks like a genuine, unrelated build fix.
