echo "Calculating Bluetooth address"
if grep -q "Pi 4" /proc/device-tree/model; then
  BDADDR=
else
  SERIAL=`cat /proc/device-tree/serial-number | cut -c9-`
  B1=`echo $SERIAL | cut -c3-4`
  B2=`echo $SERIAL | cut -c5-6`
  B3=`echo $SERIAL | cut -c7-8`
  BDADDR=`printf b8:27:eb:%02x:%02x:%02x $((0x$B1 ^ 0xaa)) $((0x$B2 ^ 0xaa)) $((0x$B3 ^ 0xaa))`
fi

echo "Initializing Bluetooth hardware"
/usr/bin/hciattach /dev/ttyAMA0 bcm43xx 921600 noflow - $BDADDR

echo "Starting Bluetooth demon"
/usr/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf -P sap,hostname -d &

echo "Enabling Bluetooth"
/usr/bin/bluetoothctl <<EOF
power on
discoverable on
agent on
default-agent
exit
EOF

echo "Configuring HCI"
/usr/bin/hciconfig hci0 up
/usr/bin/hciconfig hci0 piscan
/usr/bin/hciconfig hci0 sspmode 1

echo "Bluetooth devices"
/usr/bin/hcitool dev

echo "Starting A2DP agent"
/opt/btspeaker/a2dp-agent.py &
sleep 2

echo "Starting BlueALSA Sink"
/usr/bin/bluealsa -i hci0 -p a2dp-sink &
sleep 2

echo "Starting BlueALSA aplay"
/usr/bin/bluealsa-aplay --pcm-buffer-time=250000 00:00:00:00:00:00 &

