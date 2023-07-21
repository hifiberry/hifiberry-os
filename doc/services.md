# Supported services

The following services are currently supported on HiFiBerryOS:

* Airplay 2
* Analog input on DAC+ ADC
* Bluetooth
* mpd
* Roon (not on the Raspberry Pi Zero)
* Spotify (not on the Raspberry Pi Zero)
* Squeezebox (not on the Raspberry Pi Zero)
* Snapcast (not on the Raspberry Pi Zero)


## Airplay 2

Shairport-sync implements support for the newer Airplay 2 protocol.

## Analog input

alsaloop is used to enable input from a analoge input of the DAC+ ADC cards. It just uses alsaloop to copy data from the input
to the output.

## Bluetooth

This module enables HiFiBerryOS to act as a Bluetooth speaker. It uses BlueZ and BlueALSA to implement bluetooth functionalities. MPRIS is implemented using mpris-proxy

## MPD

MPD is a multi-purpose media player daemon that can be used to play local files, but also listen to web radio streams.
MPRIS is implemented using mpd-mpris.

## Roon RAAT

Roon is a high-end music player. It uses a proprietary protocol. Therefore, the sources for this player are not included.

## Spotifyd

Spotifyd implements a Spotify connect receiver. 

## Squeezelite

Squeezelite implements the Logitech Squeezebox protocol enabling the system to connect to a Logitech Media Server. MPRIS support is implemented separataly by lms-mpris. 

## Snapcast

A snapcast player is included, but is still experimental.

# Systemd services and config files

|Service|config files|systemd services|
|---|---|---|
|alsaloop|-|alsaloop.service|
|bluetooth audio|/etc/bluetooth/main.conf|bluetoothd.service, bluealsa.service, bluealsa-aplay.service|
|mpd|/etc/mpd.conf|mpd.service, mpd-mpris.service|
|roon|/etc/hifiberry_raat.conf|raat.service|
|shairport-sync|/etc/shairport-sync.conf|shairport-sync.service|
|spotifyd|/etc/spotifyd.conf|spotify.service|
|squeezelite|/var/squeezelite/squeezelite.name|squeezelite.service, lmsmpris.service|
|snapcast|/etc/snapcastmpris.conf|snapcastmpris.service|
