[![GitHub contributors](https://img.shields.io/github/contributors/Naereen/StrapDown.js.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/contributors/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
# HiFiBerryOS

HiFiBerryOS is our version of a minimal Linux distribution optimized for audio playback. 
The goal isn't to add as much functionality as possible, but to keep it small. Therefore, 
it is based on Buildroot and it's not possible to use package managers to add more 
software.

There is a robust update mechanism that will not overwrite the system, but switch between
the current and the new version (they run on different partitions). This is documented in more detail at [doc/updater.md](doc/updater.md).

## User interface

The user interface is based on the [Bang & Olufsen Beocreate project](https://github.com/bang-olufsen/create).

## Services

At the moment, the following services are supported:

- Spotify (using Spotifyd) - requires a paid Spotify subscription
- Airplay (using shairport)
- Squeezebox (using squeezelite)
- Bluetooth A2DP sind (using BlueZ 5)
- Roon - requires a Roon subscription
- MPD
- Snapcast (experimental)
- analogue input on DAC+ ADC (using alsaloop)

## Tools 

Additional tools that are available:

- sox
- HiFiBerry dsptoolkit

Note that there is no direct support for local music archives (e.g. MP3 files on a NAS) yet. If you have a local
music collection, you need to use an additional music server to stream music to HiFiBerryOS, e.g.

- Roon 
- Logitech Media Server
- iTunes

You might also configure the included music player daemon, but you have to do this from command line. A simple MPD UI names ympd is running on HTTP port 9000.

## Integrations and additional functionalities

There are several ways to add functionalities to HiFiBerryOS or integrate it into other systems.

### Controlling the system

The main backend controller application is called [audiocontrol](https://github.com/hifiberry/audiocontrol2) and offers an API that can be used to start/stop players, switch sources or retrieve metadata.
This is often the easiest way if you want to integrate it into other systems, e.g. a automation system.

### Extending audiocontrol

Audiocontrol provides a [plugin system](https://github.com/hifiberry/audiocontrol2/blob/master/doc/extensions.md) that can be used to add more complex integrations.

### Adding packages

HiFiBerryOS is based on buildroot. This means, you can't easily install additional software from command line. Even if you do, it will be gone after the next update as an update will replace the full filesystem. You need top integrate additonal software via the [Buildroot build system](https://buildroot.org/)

### Adding UI components

The UI also uses a plugin concept. Plugins are called extensions. Have a look at the [Beocreate documentation](https://github.com/bang-olufsen/create/tree/master/Documentation)

## Contributions
We're looking forward to your contributions. Depending on functionality and code quality, we will decide if a contribution will be included in the base system or will be provided as a user-contributed module that users need to install by themselve.

