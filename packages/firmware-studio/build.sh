#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE="firmware-studio"
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
    --no-run-lintian \
    --verbose

# Move build artifacts to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true

# Clean up build directory
cd "$SCRIPT_DIR"
rm -rf "$BUILD_DIR"

# Clean up old artifacts in script directory
find "$SCRIPT_DIR" -maxdepth 1 -name "${PACKAGE}_*.buildinfo" -delete
find "$SCRIPT_DIR" -maxdepth 1 -name "${PACKAGE}_*.changes" -delete

# Keep only the most recent .deb file
LATEST_DEB=$(ls -t "$SCRIPT_DIR"/${PACKAGE}_*.deb 2>/dev/null | head -1)
if [ -n "$LATEST_DEB" ]; then
    ls -t "$SCRIPT_DIR"/${PACKAGE}_*.deb | tail -n +2 | xargs -r rm -f
    echo "Kept latest package: $(basename $LATEST_DEB)"
fi

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/${PACKAGE}_*.deb 2>/dev/null || echo "No packages found"
