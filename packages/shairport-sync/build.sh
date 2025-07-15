#!/bin/bash

# Exit on error
set -e

PACKAGE="hifiberry-shairport"

# Extract version from changelog as single source of truth
SCRIPT_DIR="$(dirname $(realpath $0))"
VERSION=$(grep -m1 "^${PACKAGE}" "${SCRIPT_DIR}/src/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
echo "Version from changelog: $VERSION"

# Extract Shairport Sync version from debian/rules
SHAIRPORT_VERSION=$(grep "^SHAIRPORT_VERSION" "${SCRIPT_DIR}/src/debian/rules" | sed 's/SHAIRPORT_VERSION ?= //')
SHAIRPORT_COMMIT=$(grep "^SHAIRPORT_COMMIT" "${SCRIPT_DIR}/src/debian/rules" | sed 's/SHAIRPORT_COMMIT ?= //')

echo "Building with Shairport Sync version: $SHAIRPORT_VERSION (commit: $SHAIRPORT_COMMIT)"

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

# Parse arguments
NO_UPDATE=false
for arg in "$@"; do
  case $arg in
    --no-update)
      NO_UPDATE=true
      shift
      ;;
  esac
done

echo "Building $PACKAGE version $VERSION"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source files to build directory
echo "Copying source files..."
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

