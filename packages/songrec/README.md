# SongRec Package

This package builds SongRec - an open-source Shazam client for Linux, written in Rust.

## About SongRec

SongRec is a music recognition application that can identify songs playing from:
- Microphone input
- Audio files (MP3, FLAC, WAV, OGG, and more with FFmpeg)
- System speakers (on compatible PulseAudio/PipeWire setups)

Features:
- GUI and command-line interfaces
- Real-time song recognition
- Recognition history with CSV export
- Multiple audio source support

## Building

To build the Debian package:

```bash
./build.sh
```

This will:
1. Clone the SongRec repository from GitHub
2. Install required build dependencies
3. Compile SongRec with Rust/Cargo (release mode)
4. Create a Debian package

## Cleaning

To clean up build artifacts:

```bash
./clean.sh
```

Or use the build script with --clean flag:

```bash
./build.sh --clean
```

## Dependencies

Build dependencies:
- Rust/Cargo (1.70+)
- build-essential
- libasound2-dev
- libpulse-dev
- libgtk-3-dev
- libssl-dev
- intltool
- debhelper
- dh-cargo

Runtime dependencies:
- libasound2
- libpulse0
- libgtk-3-0
- libssl3 or libssl1.1

## Source

Original project: https://github.com/marin-m/SongRec

## License

GPL-3.0 (as per upstream project)
