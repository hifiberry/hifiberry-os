#!/bin/bash

echo "Cleaning hifiberry-pipewire-configs build artifacts..."

# Remove build artifacts
rm -f ../*.deb
rm -f ../*.changes
rm -f ../*.buildinfo
rm -f ../*.dsc
rm -f ../*.tar.*
rm -rf debian/hifiberry-pipewire-configs/
rm -rf debian/.debhelper/
rm -f debian/debhelper-build-stamp
rm -f debian/files

echo "Clean completed"
