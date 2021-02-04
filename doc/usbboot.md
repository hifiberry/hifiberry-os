# Booting HiFiBerryOS from an USB stick

Currently HiFiBerryOS does NOT boot successfully  from an USB, but there has been some work to allow this in the future. Currently the system hangs in the boot process!

We're only working on the Pi4. While the Pi3 can also boot from USB mass storage devices, the boot loader is very different from the Pi4's bootloader and we did not look into this.

## Prepare the Pi 4

With the default firmware and settings, the Pi4 won't boot from USB devices. You first need to prepare the Pi's bootloader and configuration:
[Pi USB boot](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/msd.md)

To make sure, everything is set up correctly, we recommend to boot Rasberry Pi OS. If this boots correctly, the firmware configuration is correct. Don't try the next steps until 
your Pi boots Raspbian!

## Write HiFiBerryOS to an USB stick

Just use an SD card imager of your choice and write the HiFiBerryOS image to an USB memory stick instead of an SD card.

## Change the boot configuration of HiFiBerryOS

Edit the cmdline.txt file on the FAT partition as follows:

```
root=/dev/sda2 rootwait console=tty5 systemd.show_status=1
```

## Boot

As of today, the system will still hang at some point in the boot process. As this is a feature with a lower priority for us, it might take some time until this will be working.
