#!/bin/bash

# Exit on error
set -e

PACKAGE="hifiberry-baseconfig"

# Extract version from changelog as single source of truth
SCRIPT_DIR="$(dirname $(realpath $0))"
VERSION=$(head -1 "${SCRIPT_DIR}/src/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
echo "Version from changelog: $VERSION"

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
echo "Copying source files..."
cp -r "$SRC_DIR"/* "$BUILD_DIR/"

# Change to build directory
cd "$BUILD_DIR"

# Build package using sbuild
echo "Using sbuild..."
sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    $DIST_ARG \
    $CHROOT_ARG \
    --build-dir="$BUILD_DIR" \
    --verbose

# Move build artifacts to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true

# Clean up build directory
echo "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/*.deb 2>/dev/null || echo "No packages found"

