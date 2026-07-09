# firmware-studio

Firmware binaries for the microcontrollers on HiFiBerry **Studio** sound cards,
together with a helper to flash them over UPDI using
[`pymcuprog`](https://pypi.org/project/pymcuprog/).

## Contents

| File | Description |
|------|-------------|
| `/usr/share/firmware-studio/studiodac8x-0.0.2.hex` | Studio DAC8x ATtiny402 firmware, v0.0.2 |
| `/usr/bin/flash-studio-dac8x` | Flash helper (uses `pymcuprog` over UPDI) |
| `/usr/bin/firmware-studio-setup` | One-shot setup for stock Raspberry Pi OS |

## Setup on Raspberry Pi OS

On a stock Raspberry Pi OS (Bookworm/Trixie, Pi 5 / CM5) the kernel already
ships the `hifiberry-studio-dac8x` overlay and driver, so only the repo, this
package and a bit of `config.txt` are needed.

### Automatic

`firmware-studio-setup` does everything below. Bootstrap it on a fresh system:

```sh
# add repo + install the package, then run the setup helper
echo "deb [trusted=yes] http://debianrepo.hifiberry.com trixie main" \
  | sudo tee /etc/apt/sources.list.d/hifiberry.list
sudo apt-get update
sudo apt-get install -y firmware-studio
sudo firmware-studio-setup      # add --overlay hifiberry-dac8x for the no-mixer driver
sudo reboot
# after reboot:
sudo flash-studio-dac8x
```

### Manual

1. **Add the HiFiBerry apt repository:**

   ```sh
   echo "deb [trusted=yes] http://debianrepo.hifiberry.com trixie main" \
     | sudo tee /etc/apt/sources.list.d/hifiberry.list
   sudo apt-get update
   ```

2. **Install the package** (pulls in `python3-pymcuprog`):

   ```sh
   sudo apt-get install -y firmware-studio i2c-tools
   ```

3. **Configure `/boot/firmware/config.txt`:**

   ```ini
   dtparam=i2c_arm=on          # reach the controller at I2C 0x10
   enable_uart=1               # UPDI is on the serial UART (for flashing)
   dtoverlay=hifiberry-studio-dac8x
   ```

   Use `dtoverlay=hifiberry-dac8x` instead for the plain driver without the
   ALSA mixer.

4. **Free the serial console** so the firmware can be flashed over UPDI —
   remove `console=serial0,115200` from `/boot/firmware/cmdline.txt` and disable
   the getty:

   ```sh
   sudo sed -i -E 's/console=serial0,[0-9]+ ?//' /boot/firmware/cmdline.txt
   sudo systemctl disable --now serial-getty@ttyAMA0.service
   echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
   ```

5. **Reboot**, then flash the card firmware with `sudo flash-studio-dac8x`.

## Studio DAC8x firmware

The Studio DAC8x carries an **ATtiny402** microcontroller. The firmware makes it
an I2C controller at slave address **0x10** on the Pi's I2C bus, presenting the
"universal sound-card" register map (firmware/hardware version, UUID, supported
rates/formats, per-channel volume, DAC filter, ...) and relaying control to the
four on-board PCM5242 DACs over a bit-banged soft-I2C bus.

It pairs with the `hifiberry-studio-dac8x` device-tree overlay and the
`snd-soc-hifiberry-studio-dac8x` kernel driver, which talks to the controller at
0x10.

### v0.0.2

* Per-channel volume is `master + offset` on all 8 channels (channel 0 was
  previously inconsistent and could not be attenuated via the mixer).
* All four PCM5242 DACs are initialised at start-up.

Source: <https://github.com/hifiberry/firmware-studio_dac8x> (branch `main`).

## Flashing

The microcontroller is programmed over **UPDI**, which uses the Raspberry Pi's
serial UART (GPIO TXD/RXD). Requirements:

* `pymcuprog` installed (pulled in as a dependency of this package).
* The serial **console must be disabled** on that UART, i.e. no
  `console=serial0,115200` in `/boot/firmware/cmdline.txt`, and
  `enable_uart=1` in `/boot/firmware/config.txt`. Otherwise programming fails.

Then:

```sh
# newest studiodac8x firmware, default port /dev/serial0
sudo flash-studio-dac8x

# explicit port / hex file
sudo flash-studio-dac8x /dev/serial0 /usr/share/firmware-studio/studiodac8x-0.0.2.hex
```

Check the controller responds after flashing (firmware version at registers
0x00-0x02):

```sh
printf '%d.%d.%d\n' \
  "$(i2cget -y 1 0x10 0x00)" "$(i2cget -y 1 0x10 0x01)" "$(i2cget -y 1 0x10 0x02)"
```
