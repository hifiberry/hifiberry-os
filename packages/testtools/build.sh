#!/bin/bash

# Exit on error
set -e

PACKAGE="testtools"
SRC_DIR="$(dirname $(realpath $0))/src"
SCRIPT_DIR="$(dirname $(realpath $0))"

# Extract version from changelog
if [ -f "$SRC_DIR/debian/changelog" ]; then
    VERSION=$(head -n 1 "$SRC_DIR/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
    echo "Version from changelog: $VERSION"
else
    echo "ERROR: Changelog not found at $SRC_DIR/debian/changelog"
    exit 1
fi

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

