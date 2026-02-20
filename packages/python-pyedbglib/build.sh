#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE="python3-pyedbglib"
SCRIPT_DIR="$(dirname $(realpath $0))"

# Extract version from changelog
VERSION=$(head -1 "$SCRIPT_DIR/src/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
echo "Version from changelog: $VERSION"

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi
BUILD_DIR="/tmp/${PACKAGE}-build"
SCRIPT_DIR="$(dirname $(realpath $0))"
REPO_URL="https://github.com/microchip-pic-avr-tools/pyedbglib.git"
REPO_DIR="pyedbglib"

echo "Building $PACKAGE version $VERSION"

# Clone the repository if it doesn't exist; otherwise, update it
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository from $REPO_URL..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "Repository already exists. Updating..."
    cd "$REPO_DIR"
    git pull
    cd ..
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source files to build directory
cp -r "$REPO_DIR" "$BUILD_DIR/"
cp -r "$SCRIPT_DIR/src/debian" "$BUILD_DIR/"

# Change to build directory
cd "$BUILD_DIR"

# Build package using sbuild
echo "Using sbuild..."
sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    --enable-network \
    $DIST_ARG \
    --build-dir="$BUILD_DIR" \
    --no-run-lintian \
    --verbose

# Move only the .deb to script directory, discard other build artifacts
echo "Moving package file..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true

# Clean up build directory
cd "$SCRIPT_DIR"
rm -rf "$BUILD_DIR"

# Clean up old artifacts in script directory
echo "Cleaning up old build artifacts..."
find "$SCRIPT_DIR" -maxdepth 1 -name "${PACKAGE}_*.buildinfo" -delete
find "$SCRIPT_DIR" -maxdepth 1 -name "${PACKAGE}_*.changes" -delete

# Keep only the most recent .deb file
LATEST_DEB=$(ls -t "$SCRIPT_DIR"/${PACKAGE}_*.deb 2>/dev/null | head -1)
if [ -n "$LATEST_DEB" ]; then
    # Remove all .deb files except the latest one
    ls -t "$SCRIPT_DIR"/${PACKAGE}_*.deb | tail -n +2 | xargs -r rm -f
    echo "Kept latest package: $(basename $LATEST_DEB)"
fi

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/${PACKAGE}_*.deb 2>/dev/null || echo "No packages found"


