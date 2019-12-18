# HiFiBerryOS

HiFiBerryOS is our version of a minimal Linux distribution optimized for audio playback. 
The goal isn't to add as much functionality as possible, but to keep it small. Therefore, 
it is based on Buildroot and it's not possible to use package managers to add more 
software.

There is a robust update mechanism that will not overwrite the system, but switch between
the current and the new version (they run on different partitions)

At the moment, the following services are supported:

- Spotify (using Spotifyd) - requires a paid Spotify subscription
- Airplay (using shairport)
- Squeezebox (using squeezelite)
- Bluetooth A2DP sind (using BlueZ 5)
- Roon - requires a Roon subscription
- MPD
- Snapcast (experimental)
- analogue input on DAC+ ADC (using alsaloop)

Additional tools that are available:

- sox
- HiFiBerry dsptoolkit

Note that there is no direct support for local music archives (e.g. MP3 files on a NAS). If you have a local
music collection, you need to use an additional music server to stream music to HiFiBerryOS, e.g.

- Roon 
- Logitech Media Server
- iTunes

