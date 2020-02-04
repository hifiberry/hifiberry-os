#!/bin/bash
# This should be used on a Pi running Raspbian to compile the latest Spotifyd version
# It's not used anymore as we're now using the official spotifyd binary
if [ "$1" == "clean" ]; then
  cargo clean
fi
cargo build --release --no-default-features --features alsa_backend,dbus_mpris
