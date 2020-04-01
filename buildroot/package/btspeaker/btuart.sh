#!/bin/sh

FIXCONFIG=`cat /boot/config.txt | grep "pi3-miniuart-bt"`
if [ "$FIXCONFIG" != "" ]; then
	mount -o remount,rw /boot
	cat /boot/config.txt | grep -v "pi3-miniuart-bt" > /tmp/config.txt
	cp /boot/config.txt /boot/config.txt.bak
	mv /tmp/config.txt /boot/config.txt
	sync
	echo "Fixing Bluetooth UART configuration" >> /tmp/reboot	
fi	

echo "Calculating Bluetooth address"
if grep -q "Pi 4" /proc/device-tree/model; then
	BDADDR=
	PI3=0
else
	SERIAL=`cat /proc/device-tree/serial-number | cut -c9-`
	B1=`echo $SERIAL | cut -c3-4`
	B2=`echo $SERIAL | cut -c5-6`
	B3=`echo $SERIAL | cut -c7-8`
	BDADDR=`printf b8:27:eb:%02x:%02x:%02x $((0x$B1 ^ 0xaa)) $((0x$B2 ^ 0xaa)) $((0x$B3 ^ 0xaa))`
fi

/opt/hifiberry/bin/bootmsg "Attaching Bluetooth interface"

uart0_pins="`wc -c /proc/device-tree/soc/gpio@7e200000/uart0_pins/brcm\,pins | cut -f 1 -d ' '`"
if [ "$uart0_pins" != "16" ] ; then
	if [ "$PI3" != "0" ]; then
		PI3=1
	fi
fi

if [ "$PI3" == "1" ]; then
	echo "Looks like an Raspberry Pi 3 without flow control, BT audio will not work reliably"
        /opt/hifiberry/bin/bootmsg "Bluetooth not supported on Pi3B"
        exit 1
fi

# This line is necessary to sort out the flow control pins
stty -F /dev/ttyAMA0 115200 raw -echo
/usr/bin/hciattach -n /dev/ttyAMA0 bcm43xx 3000000 flow - $BDADDR
if [ "$?" != "0" ]; then
	echo "Failed"
	/opt/hifiberry/bin/bootmsg "Attaching Bluetooth interface"
fi
