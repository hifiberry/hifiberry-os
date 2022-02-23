# Using an IR remote

You can control your HiFiBerryOS speakers using any remote. You can change volume or skip and pause songs from any input.

## What you need

* IR receiver (make sure it has the matching frequency for your remote (38 kHz is usually a good guess))
* 3 jumper cables
* IR remote

## Adding the hardware

1. Look up the datasheet of your IR receiver to get the correct pins. There are usually 3 pins, GND, VCC and OUT. The order of these can change between models so make sure you have the correct pin layout or else you will destroy the receiver.

2. The default data pin for IR is GPIO16 on the Raspberry. If you can't use this pin you can use a different pin on your Pi, but remember to change the config file (explained later). Connect GND to a ground pin on your board, VCC to 5V or 3.3V (depending on your receiver) and OUT to GPIO16.

3. Double check that the pins are connected correctly and turn on your Raspberry Pi.

## Software configuration

### Different GPIO pin

If you used a different pin than GPIO16 you need to change the config file. Else you can skip these steps.

1. Turn off your Pi and remove the sd card

2. Plug in the sd card into your pc. You should see only one partition.

3. Open `config.txt` using a text editor and find the following line `dtoverlay=gpio-ir,gpio_pin=16`

4. Change `gpio_pin=16` to whatever pin you used.

5. Save the file, add the sd card to your Pi and boot.

### Generating a keymap for your remote

The keymap is the configuration file, which maps the keys on your remote to actions on your Pi.
As there is no standard configuration for each remote, you have to create your own.
The keymap is loaded automatically on boot and is copied over when running a update, so you only have to do these steps once or when you want to use a different remote.

1. Connect using SSH

2. Run `ir-keytable` and verfiy the output:
```
Found /sys/class/rc/rc0/ (/dev/input/event0) with:
    Name: gpio_ir_recv
    Driver: gpio_ir_recv, table: rc-rc6-mce
    LIRC device: /dev/lirc1
    Attached BPF protocols: Operation not permitted
    Supported kernel protocols: lirc rc-5 rc-5-sz jvc sony nec sanyo mce_kbd rc-6 sharp xmp imon 
    Enabled kernel protocols: lirc rc-6 
    bus: 25, vendor/product: 0001:0001, version: 0x0100
    Repeat delay = 500 ms, repeat period = 125 ms
```
3. Run `ir-keytable -p all`

4. Run `ir-keytable -t` and press some buttons on your remote. You should see an output like this:
```
4019.940078: lirc protocol(rc6_0): scancode = 0x1 toggle=1
4019.940124: event type EV_MSC(0x04): scancode = 0x01
4019.940124: event type EV_SYN(0x00).
```
5. The important part is `scancode = 0x01` and `protocol(rc6_0)`. Press every key that you want to use and note their scancode

6. Now we can change the keymap for the remote. To edit the default keymap, open the file `/etc/rc_keymaps/keymap.toml` with an editor. You should see something like this:
```
[[protocols]]
name = "rc6_0"
protocol = "rc6"
variant = "rc6_0"
[protocols.scancodes]
0x10 = "KEY_VOLUMEUP"
0x11 = "KEY_VOLUMEDOWN"
```
7. Add your scancodes or change the existing ones in the format `SCANCODE = "KEYCODE"`. Valid (working) keycodes are *KEY_VOLUMEUP, KEY_VOLUMEDOWN, KEY_PLAYPAUSE, KEY_NEXT, KEY_PREVIOUS*. If your remote uses another protocol, you need to change that aswell.

8. Save and close the file

9. Run `/usr/bin/ir-keytable --write=/etc/rc_keymaps/keymap.toml -c`

10. Test your configuration using `ir-keytable -t`. You should now see lines like 
```
4950.990117: event type EV_KEY(0x01) key_down: KEY_VOLUMEUP(0x0073)
```

11. Check if you can control your speakers using the remote
