#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE="hifiberry-analoginput"

# Parse version from debian/changelog
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
VERSION=$(grep -m1 "^${PACKAGE}" "${SCRIPT_DIR}/src/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not parse version from debian/changelog"
    exit 1
fi
echo "Parsed version from changelog: $VERSION"

# Check for DIST environment variable
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
SRC_DIR="${SCRIPT_DIR}/src"

# Clean function
clean() {
    echo "Cleaning up build files..."
    rm -rf "$BUILD_DIR"
    rm -f ${PACKAGE}*.build ${PACKAGE}*.changes ${PACKAGE}*.dsc ${PACKAGE}*.deb ${PACKAGE}*.buildinfo ${PACKAGE}*.tar.gz
    echo "Cleanup completed."
}

if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

echo "Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Copying source files..."
cp -r "$SRC_DIR/"* "$BUILD_DIR/"

cd "$BUILD_DIR"

echo "Building package with sbuild..."
sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    --enable-network \
    $DIST_ARG \
    $CHROOT_ARG \
    --build-dir="$BUILD_DIR" \
    --verbose

echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true

echo "Debian package build completed."
echo "Built packages:"
ls -la "$SCRIPT_DIR"/*.deb 2>/dev/null || echo "No packages found"