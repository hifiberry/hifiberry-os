#!/bin/bash

echo "Cleaning up build artifacts..."
rm -rf src/librespot-source/
rm -rf src/target/
rm -rf src/debian/cargo_home/
rm -rf src/debian/rustup_home/
rm -f src/../*.deb src/../*.changes src/../*.buildinfo src/../*.dsc

rm -f hifiberry-librespot_*.changes
rm -f hifiberry-librespot_*.dsc
rm -f hifiberry-librespot_*.buildinfo
rm -r hifiberry-librespot_*.build
rm -r hifiberry-librespot_*.tar.gz
