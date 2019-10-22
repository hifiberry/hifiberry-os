#!/bin/sh

PI3=`cat /proc/device-tree/model | grep "Pi 3 M"`
if [ "$PI3" == "" ]; then
	echo "BT audio does not work reliably on the Pi3, disabling it"
	systemctl disable bluetooth
	systemctl disable bluealsa
	systemctl disable bluealsa-aplay
fi

