#!/bin/bash

set -e

# Configuration
PACKAGE_NAME="hifiberry-pipewire"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Extract version from changelog
cd src
FULL_VERSION=$(head -1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
echo "Version from changelog: $FULL_VERSION"

# Extract PipeWire base version (everything before the last dot and suffix)
PIPEWIRE_VERSION=$(echo "$FULL_VERSION" | sed 's/\.[^.]*$//')
echo "PipeWire version: $PIPEWIRE_VERSION"

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi

echo "Building package with sbuild..."

# Check if PipeWire version in rules file is consistent with changelog
RULES_PIPEWIRE_VERSION=$(grep '^PIPEWIRE_VERSION = ' debian/rules | sed 's/PIPEWIRE_VERSION = //')
if [[ ! "$FULL_VERSION" =~ ^${RULES_PIPEWIRE_VERSION}(\.|$) ]]; then
    echo "ERROR: PipeWire version in rules file ($RULES_PIPEWIRE_VERSION) is not compatible with package version ($FULL_VERSION)"
    echo "Package version should start with the PipeWire version from rules file"
    echo "Please update debian/rules or debian/changelog to ensure consistency"
    exit 1
fi

# Make sure debian/rules is executable
chmod +x debian/rules

# Use sbuild to build the package
sbuild --chroot-mode=unshare --no-clean-source --enable-network \
       --extra-repository='deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware' \
       --extra-repository='deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware' \
       --build-dep-resolver=apt $DIST_ARG

# Go back to parent directory
cd ..

echo "Package build completed."
echo "Built packages:"
ls -la *.deb 2>/dev/null || echo "No .deb files found"