#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

# Define variables
PACKAGE="riaa"
DEB_PACKAGE="ladspa-riaa"
REPO_URL="https://github.com/hifiberry/riaa.git"

export BUILD_DIR="/tmp/${PACKAGE}-build"

if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    export DIST_ARG="--dist=$DIST"
    export CHROOT_ARG="--chroot=$CHROOT"
else
    echo "No DIST environment variable set, using sbuild default"
    export DIST_ARG=""
    export CHROOT_ARG=""
fi

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$BUILD_DIR"
    rm -f $PACKAGE*.build $PACKAGE*.changes $PACKAGE*.dsc $PACKAGE*.deb $PACKAGE*.buildinfo $PACKAGE*.tar.gz
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

echo "Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Step 1: Clone or update the GitHub repository
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    cd "$PACKAGE"
    git pull
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
    cd "$PACKAGE"
fi

# Step 2: Build Debian package using make deb
echo "Building $PACKAGE Debian package..."
make deb

# Remove debug symbols package
rm -f ../ladspa-riaa-dbgsym*.deb

# Step 3: Move built packages back to package directory
cd ..
mv $BUILD_DIR/$DEB_PACKAGE_*.deb . 2>/dev/null || true
mv $BUILD_DIR/$DEB_PACKAGE_*.build . 2>/dev/null || true
mv $BUILD_DIR/$DEB_PACKAGE_*.buildinfo . 2>/dev/null || true
mv $BUILD_DIR/$DEB_PACKAGE_*.changes . 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -lh $DEB_PACKAGE*.deb
