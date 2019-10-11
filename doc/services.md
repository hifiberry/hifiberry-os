# Supported services

The following services are currently supported on HiFiBerryOS:

* Airplay 1
* Analog input on DAC+ ADC
* Bluetooth
* mpd
* Roon
* Spotify
* Squeezebox


## Airplay 1

Shairport-sync implements support for the older Airplay 1 protocol. This is still supported today. Airplay 2 that offers 
some additional features is not supported.

## Analog input

alsaloop is used to enable input from analoge input of the DAC+ ADC cards. It just uses alsaloop to copy data from the input
to the output. There is no MPRIS support for this at the moment.

## Bluetooth

This module enables HiFiBerryOS to act as a Bluetooth speaker. It uses BlueZ and BlueALSA to implement this. MPRIS is implemented my mpris-proxy

## MPD

MPD is a multi-purpose media player daemon that can be used to play local files, but also listen to web radio streams.
MPRIS is implemented using mpd-mpris.

## Roon RAAT

Roon is a high-end music player. It uses a proprietary protocol. Therefore, the sources for this player are not included.

## Spotifyd

Spotifyd implements a Spotify connect receiver. 

## Squeezelite

Squeezelite implements the Logotech Squeezebox protocol enabling the system to connect to a Logitech Media Server. MPRIS support is implemented separataly by lms-mpris. 



# Systemd services and config files

|Service|config files|systemd services|
|---|---|---|
|alsaloop|-|-|
|bluetooth audio|-|-|
|mpd|-|-|
|roon|-|-|
|shairport-sync|-|-|
|spotifyd|-|-|
|squeezelite|-|-|
