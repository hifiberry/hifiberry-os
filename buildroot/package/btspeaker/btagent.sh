#!/bin/sh

# Make device discoverable
/bin/bluetoothctl <<EOF
power on
discoverable on
pairable on
agent on
EOF

# Use pin if it is configured
if [ -f /etc/bluetooth/pin.conf ]; then
	/usr/bin/bt-agent -c NoInputNoOutput -p /etc/bluetooth/pin.conf
else
	/usr/bin/bt-agent -c NoInputNoOutput
fi
