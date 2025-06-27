#!/bin/bash

# Exit on error
set -e

PACKAGE="hifiberry-shairport"
VERSION="4.3.7.2"
DIST="bullseye"
CHROOT="${DIST}-amd64-sbuild"
BUILD_DIR="/tmp/${PACKAGE}-build"
SRC_DIR="$(dirname $(realpath $0))/src"
SCRIPT_DIR="$(dirname $(realpath $0))"

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
    --dist="$DIST" \
    --chroot="$CHROOT" \
    --build-dir="$BUILD_DIR" \
    --verbose

# Move build artifacts to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true

# Run lintian on the built package
echo "Running lintian to check package compliance..."
if ls "$SCRIPT_DIR"/*.deb 1> /dev/null 2>&1; then
    for deb_file in "$SCRIPT_DIR"/*.deb; do
        echo "Checking $deb_file with lintian..."
        lintian --info --display-info --display-experimental --pedantic "$deb_file" || true
        echo "Lintian check completed for $(basename "$deb_file")"
        echo "----------------------------------------"
    done
else
    echo "No .deb files found to check with lintian"
fi

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/*.deb 2>/dev/null || echo "No packages found"

