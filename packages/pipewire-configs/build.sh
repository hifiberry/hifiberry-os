#!/bin/bash

# Get version from changelog
VERSION=$(dpkg-parsechangelog -S Version)
DIST=$(dpkg-parsechangelog -S Distribution)

echo "Building hifiberry-pipewire-configs version $VERSION for $DIST"

# Build the package
dpkg-buildpackage -us -uc -b

echo "Build completed successfully"
