#!/bin/bash

# Exit on error
set -e

PACKAGE="hifiberry-squeezelite"
VERSION="2.0.0.1542"

# Version consistency check
SCRIPT_DIR="$(dirname $(realpath $0))"
CHANGELOG_VERSION=$(grep -m1 "^${PACKAGE}" "${SCRIPT_DIR}/src/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
if [ "$VERSION" != "$CHANGELOG_VERSION" ]; then
    echo "ERROR: Version mismatch!"
    echo "  build.sh VERSION: $VERSION"
    echo "  debian/changelog: $CHANGELOG_VERSION"
    echo "Please update VERSION in build.sh or debian/changelog to match."
    exit 1
fi
echo "Version consistency check passed: $VERSION"

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    CHROOT="${DIST}-amd64-sbuild"
    DIST_ARG="--dist=$DIST"
    CHROOT_ARG="--chroot=$CHROOT"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
    CHROOT_ARG=""
fi
BUILD_DIR="/tmp/${PACKAGE}-build"
SRC_DIR="$(dirname $(realpath $0))/src"

echo "Building $PACKAGE version $VERSION"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source files to build directory
cp -r "$SRC_DIR/"* "$BUILD_DIR/"

# Change to build directory
cd "$BUILD_DIR"

# Build package using sbuild
echo "Using sbuild..."
sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    --enable-network \
    $DIST_ARG \
    $CHROOT_ARG \
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

