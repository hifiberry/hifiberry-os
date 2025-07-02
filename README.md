[![GitHub contributors](https://img.shields.io/github/contributors/hifiberry/hifiberry-os.svg)](https://GitHub.com/hifiberry/hifiberry-os/graphs/contributors/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
# HiFiBerryOS

**The current HiFiBerryOS releases are not maintained anymore. No further updates are planned. We are working on a completely new system. You can check the hbosng branch of this repository.
We can't and won't say what functionality will be released when. This also means, there will be no new feature implementations or bug fixes from us on the "old" HiFIBerryOR or HiFiBerryOS64 releases anymore.
For updates on the progress, you might subscribe to our [blog](https://hifiberry.com/blog).**


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

- Spotify (using [a fork of Spotifyd](https://github.com/hifiberry/spotifyd)) - requires a paid Spotify subscription
- Airplay (using [shairport](https://github.com/mikebrady/shairport-sync))
- Squeezebox (using [squeezelite](https://github.com/ralph-irving/squeezelite))
- Bluetooth A2DP sink (using [BlueZ 5](http://www.bluez.org/))
- Roon - requires a Roon subscription
- [MPD](https://github.com/MusicPlayerDaemon/MPD)
- Snapcast (experimental, using [Snapcast](https://github.com/badaix/snapcast) and [SnapcastMPRIS](https://github.com/hifiberry/snapcastmpris))
- Analogue input on DAC+ ADC with input detection (using [a custom alsaloop implementation](https://github.com/hifiberry/alsaloop/))
- Webradio (experimental)

## Tools 

Additional tools that are available:

- [sox](http://sox.sourceforge.net/)
- [HiFiBerry dsptoolkit](https://github.com/hifiberry/hifiberry-dsp)

## Integrations and additional functionalities

There are several ways to add functionalities to HiFiBerryOS or integrate it into other systems.

### Controlling the system

The main backend controller application is called [audiocontrol](https://github.com/hifiberry/audiocontrol2) and offers an API that can be used to start/stop players, switch sources or retrieve metadata.
This is often the easiest way if you want to integrate it into other systems, e.g. a automation system.

### Extending audiocontrol

Audiocontrol provides a [plugin system](https://github.com/hifiberry/audiocontrol2/blob/master/doc/extensions.md) that can be used to add more complex integrations.Also have a look at the ["Anatomy of a controller plugin"](https://github.com/hifiberry/audiocontrol2/blob/master/doc/rotary-controller-plugin.md)

### Adding packages

HiFiBerryOS is based on buildroot. This means, you can't easily install additional software from command line. Even if you do, it will be gone after the next update as an update will replace the full filesystem. You need to integrate additonal software via the [Buildroot build system](https://buildroot.org/)

### Adding UI components

The UI also uses a plugin concept. Plugins are called extensions. Have a look at the [Beocreate documentation](https://github.com/bang-olufsen/create/tree/master/Documentation)

## How it works / technical documentation

You can find technical documentation in [the repository's doc folder](doc/)

## Building a disk image
[The documentation for building images from source can be found here](/doc/building.md)

## Contributions
We're looking forward to your contributions. Depending on functionality and code quality, we will decide if a contribution will be included in the base system or will be provided as a user-contributed module that users need to install by themselve.

