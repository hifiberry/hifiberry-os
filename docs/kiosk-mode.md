# Kiosk Mode

Replaces the full Raspberry Pi Desktop (RPD) with a minimal browser kiosk that displays a single web page — by default the now-playing-minimal view.

## Stack

```
getty@tty1 autologin
    → bash_profile
        → cage  (Wayland kiosk compositor — handles Pi 5 vc4/v3d split GPU)
            → cog  (WPE WebKit browser — ~150 MB RAM vs ~450 MB for Chromium)
```

lightdm and the RPD desktop are disabled but not removed. Reverting re-enables them.

## Setup

```bash
cd kiosk-mode
sudo ./kiosk-mode.sh setup
```

With options:

```bash
sudo ./kiosk-mode.sh setup --scale=1.5
sudo ./kiosk-mode.sh setup --url=http://localhost/now-playing-minimal
sudo ./kiosk-mode.sh setup --url=http://localhost/now-playing-minimal --scale=1.3
```

| Option | Default | Description |
|--------|---------|-------------|
| `--url` | `http://localhost/now-playing-minimal` | Page to display |
| `--scale` | `1.3` | Browser zoom factor — increase for large/distant screens |

Reboot after setup for a clean start:

```bash
sudo reboot
```

### Setup (online)

Download and execute the script directly from the online repository:

```bash
curl -Ls https://raw.githubusercontent.com/hifiberry/hifiberry-os/refs/heads/main/kiosk-mode/kiosk-mode.sh | sudo bash -s -- setup
sudo reboot
```

Options can be added just as for the local installation procedure.

## Revert to normal desktop

```bash
sudo ./kiosk-mode.sh revert
sudo reboot
```

The original `~/.bash_profile` is restored from backup (`.bash_profile.desktop-backup`) if one existed. lightdm is re-enabled and the RPD session returns on next boot.

## Status

```bash
sudo ./kiosk-mode.sh status
```

Shows whether kiosk is active, the configured URL, scale factor, and whether cage is currently running.

## Dark mode

The `?dark` query parameter is appended to the URL automatically. The `now-playing-minimal` Vue component detects this and forces the `.dark` CSS class on `<html>` for the duration of the visit.

## Scale factor

cog's `--scale` flag sets the browser zoom level (equivalent to Ctrl+Plus in a desktop browser). Useful because a TV's reported physical size is often inaccurate, giving the wrong DPI calculation.

Typical starting points:

| Display | Scale |
|---------|-------|
| Monitor (~24") | 1.0 |
| TV (~40–50") | 1.2–1.3 |
| TV (~55–70") | 1.4–1.5 |

## Notes

- SSH access is unaffected — none of these changes touch the SSH daemon.
- `cage` and `cog` are installed by the setup script if not already present.
- cog logs to `/tmp/kiosk.log` on the device.
- The Pi 5 uses a split GPU: `card1` (vc4) for display, `renderD128` (v3d) for rendering. cog's DRM backend cannot bridge this directly, which is why cage is used as an intermediary Wayland compositor.


## Optional: Hide cursor

Raspberry Pi OS may detect the HDMI output as an input device. If you have no further input devices attached, this will result with a stuck cursor in the center of the screen. To deactivate this, the HDMI device can be ignored as an input device via an udev-rule:

```bash
echo 'SUBSYSTEM=="input", ATTRS{name}=="vc4-hdmi", ENV{LIBINPUT_IGNORE_DEVICE}="1"' | sudo tee /etc/udev/rules.d/10-ignore-pointer.rules > /dev/null
```

The name of the device is dependent on the Raspberry Pi. To identify the correct device(s), run 

```bash
dmesg | grep input | grep hdmi
```
