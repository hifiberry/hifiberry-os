# Power Key

Pressing the power button on a remote control shuts the whole system down. On a
device used only as a music player that is usually what you want, but on a Pi
that also runs other services it means an accidental press takes everything
down.

This page explains where that behaviour comes from and how to change it.

## Where it comes from

No HiFiBerry component handles the power key. AudioControl reads remote
controls and binds volume, mute, play/pause, stop and next/previous — but never
`KEY_POWER`.

The key is claimed by `systemd-logind`, which acts on `KEY_POWER` from every
input device that udev tags as `power-switch`. Its default is
`HandlePowerKey=poweroff`. We ship no configuration for this, so the stock
systemd default applies on every installation.

## Changing it

Create a drop-in and reload logind:

```bash
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/10-powerkey.conf >/dev/null <<'EOF'
[Login]
HandlePowerKey=ignore
EOF
sudo systemctl restart systemd-logind
```

The three settings that make sense:

| Behaviour wanted | Configuration |
| --- | --- |
| Any press shuts down (default) | no file, or `HandlePowerKey=poweroff` |
| Power key does nothing | `HandlePowerKey=ignore` |
| Only a long press shuts down | `HandlePowerKey=ignore` and `HandlePowerKeyLongPress=poweroff` |

For the third one:

```bash
sudo tee /etc/systemd/logind.conf.d/10-powerkey.conf >/dev/null <<'EOF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
EOF
sudo systemctl restart systemd-logind
```

To go back to the default, delete the file and restart `systemd-logind` again.

Check what is actually in effect — this also shows any other drop-in that might
override yours:

```bash
systemd-analyze cat-config systemd/logind.conf | grep -i handlepowerkey
```

## The Pi 5 caveat

**On a Pi 5, `HandlePowerKey=ignore` also disables the onboard power button.**

logind cannot tell the two apart. The Pi 5's button is a `gpio-keys` device
that emits exactly the same `KEY_POWER` as a remote control, so one setting
covers both. Disabling the key removes the only way to shut a headless Pi 5
down cleanly without a network connection.

On a Pi 5, prefer `longpress`: accidental presses on the remote do nothing,
while holding the onboard button still shuts the system down.

Powering the board back on with the button is handled by the firmware, not by
logind, and is not affected by any of this.

Pi 4 and earlier have no onboard power button, so there the setting only ever
affects remote controls.

## Related

- `logind.conf(5)`, `systemd-logind(8)`
- [hifiberry-os#635](https://github.com/hifiberry/hifiberry-os/issues/635)
