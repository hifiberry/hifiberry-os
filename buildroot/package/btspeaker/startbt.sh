#!/bin/sh

modprobe hci_uart
hciattach /dev/ttyAMA0 bcm43xx 921600 noflow -
hciconfig hci0 up
/usr/libexec/bluetooth/bluetoothd &

