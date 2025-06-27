#!/bin/bash

set -e

# Configuration
PIPEWIRE_VERSION="1.4.5"
VERSION_SUFFIX="1"
PACKAGE_NAME="hifiberry-pipewire"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Construct full version string
FULL_VERSION="${PIPEWIRE_VERSION}.${VERSION_SUFFIX}"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Building package with sbuild..."

# Check if changelog version matches expected version
cd src
CHANGELOG_VERSION=$(head -1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
if [ "$CHANGELOG_VERSION" != "$FULL_VERSION" ]; then
    echo "ERROR: Changelog version ($CHANGELOG_VERSION) does not match expected version ($FULL_VERSION)"
    echo "Please update debian/changelog manually"
    exit 1
fi

# Make sure debian/rules is executable
chmod +x debian/rules

# Use sbuild to build the package
sbuild --chroot-mode=unshare --no-clean-source --enable-network \
       --extra-repository='deb http://deb.debian.org/debian bookworm non-free non-free-firmware' \
       --build-dep-resolver=aspcud

# Go back to parent directory
cd ..

echo "Package build completed."
echo "Built packages:"
ls -la src/../*.deb 2>/dev/null || echo "No .deb files found"