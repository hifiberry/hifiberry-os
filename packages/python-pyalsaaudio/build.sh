#!/bin/bash

# Exit on error
set -e

PACKAGE="python3-pyalsaaudio"
VERSION="0.11.0"
DIST="bullseye"
CHROOT="${DIST}-amd64-sbuild"
BUILD_DIR="/tmp/${PACKAGE}-build"
SRC_DIR="$(dirname $(realpath $0))/src"
SCRIPT_DIR="$(dirname $(realpath $0))"

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
    --dist="$DIST" \
    --chroot="$CHROOT" \
    --build-dir="$BUILD_DIR" \
    --no-run-lintian \
    --verbose

# Move build artifacts to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/*.deb 2>/dev/null || echo "No packages found"

