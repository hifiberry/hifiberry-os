#!/bin/bash

# Exit on error
set -e

PACKAGE="hifiberry-eeprom"
VERSION="1.2.0"
DIST="${DIST:-bullseye}"

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi

BUILD_DIR="/tmp/${PACKAGE}-build"
SRC_DIR="$(dirname $(realpath $0))/src"
SCRIPT_DIR="$(dirname $(realpath $0))"

echo "Building $PACKAGE version $VERSION"

# Check if changelog version matches build script version
if [ -f "$SRC_DIR/debian/changelog" ]; then
    CHANGELOG_VERSION=$(head -n 1 "$SRC_DIR/debian/changelog" | grep -oP '\(\K[^)]+')
    if [ "$VERSION" != "$CHANGELOG_VERSION" ]; then
        echo "ERROR: Version mismatch between build script ($VERSION) and changelog ($CHANGELOG_VERSION)"
        exit 1
    fi
    echo "Version consistency check passed: $VERSION"
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source files to build directory
cp -r "$SRC_DIR/"* "$BUILD_DIR/"

# Change to build directory
cd "$BUILD_DIR"

# Make sure debian/rules is executable
chmod +x debian/rules

# Build package using sbuild
echo "Using sbuild..."
sbuild \
    --chroot-mode=unshare \
    --enable-network \
    --no-clean-source \
    $DIST_ARG \
    --build-dir="$BUILD_DIR" \
    --verbose

# Move build artifacts to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/*.deb 2>/dev/null || echo "No packages found"

