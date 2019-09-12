# HiFiBerryOS

HiFiBerryOS is our version of a minimal Linux distribution optimized for audio playback. 
The goal isn't to add as much functionality as possible, but to keep it small. Therefore, 
it is based on Buildroot and it's not possible to use package managers to add more 
software.

Also, there is no update mechanism included at the moment.

At the moment, the following services are supported:

- Spotify (using Spotifyd)
- Airplay (using shairport)
- Squeezebox (using squeezelite)
- Bluetooth A2DP sind (using BlueZ 5)
- Roon
- MPD
- analogue input on DAC+ ADC (using alsaloop)

Additional tools that are available:

- sox
- HiFiBerry dsptoolkit

Note that there is no direct support for local music archives (e.g. MP3 files on a NAS). If you have a local
music collection, you need to use an additional music server to stream music to HiFiBerryOS, e.g.

- Roon 
- Logitech Media Server
- iTunes

