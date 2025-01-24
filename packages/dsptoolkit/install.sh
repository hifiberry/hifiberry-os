#!/bin/sh
sudo apt update
apt install python3-pip libasound2-dev libxslt1-dev libxml2-dev zlib1g-dev libxml2-dev libxslt-dev python3-dev git gcc alsa-utils

sudo pip3 install --break-system-packages pyalsaaudio RPI.GPIO

cd
git clone https://github.com/hifiberry/hifiberry-dsp
cd hifiberry-dsp
sudo python3 ./setup.py install 

for i in sigmatcp; do
 sudo systemctl stop $i
 sudo systemctl disable $i
done

sudo mkdir -p /var/lib/hifiberry

LOC=`which dsptoolkit`
sudo mkdir ~/.dsptoolkit

# Create systemd config for the TCP server
LOC=`which sigmatcpserver`

cat <<EOT >/tmp/sigmatcp.service
[Unit]
Description=SigmaTCP Server for HiFiBerry DSP
Wants=network-online.target
After=network.target network-online.target
[Service]
Type=simple
ExecStart=$LOC
StandardOutput=journal
[Install]
WantedBy=multi-user.target
EOT

sudo mv /tmp/sigmatcp.service /lib/systemd/system/sigmatcp.service

sudo systemctl daemon-reload

for i in sigmatcp; do
 sudo systemctl start $i
 sudo systemctl enable $i
done
