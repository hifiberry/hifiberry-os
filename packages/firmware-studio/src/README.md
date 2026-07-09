# firmware-studio

Firmware binaries for the microcontrollers on HiFiBerry **Studio** sound cards,
together with a helper to flash them over UPDI using
[`pymcuprog`](https://pypi.org/project/pymcuprog/).

## Contents

| File | Description |
|------|-------------|
| `/usr/share/firmware-studio/studiodac8x-0.0.2.hex` | Studio DAC8x ATtiny402 firmware, v0.0.2 |
| `/usr/bin/flash-studio-dac8x` | Flash helper (uses `pymcuprog` over UPDI) |

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
