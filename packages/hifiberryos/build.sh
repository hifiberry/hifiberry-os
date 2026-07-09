#!/bin/bash

set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE_NAME="hifiberryos-meta"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="/tmp/build-${PACKAGE_NAME}"

# Parse version from debian/changelog
VERSION=$(grep -m1 "^${PACKAGE_NAME}" "${SRC_DIR}/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')

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

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cp -r "$SRC_DIR/"* "$BUILD_DIR/"

cd "$BUILD_DIR"

# Ensure debian/rules is executable
chmod +x debian/rules

echo "Building binary packages with sbuild..."
sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    --enable-network \
    $DIST_ARG \
    $CHROOT_ARG \
    --build-dir="$BUILD_DIR" \
    --verbose

# Move artifacts back to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.dsc "$SCRIPT_DIR/" 2>/dev/null || true
mv *.tar.* "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true
mv hbos-*_${VERSION}_*.deb "$SCRIPT_DIR/" 2>/dev/null || true

echo "Build completed successfully!"
echo "Packages built in ${SCRIPT_DIR}:"
ls -la "$SCRIPT_DIR"/*${VERSION}*.deb 2>/dev/null || echo "No .deb files found"
