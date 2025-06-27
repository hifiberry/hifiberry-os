#!/bin/bash

# Exit on error
set -e

PACKAGE="python3-pyedbglib"
VERSION="2.24.2"
DIST="bullseye"
CHROOT="${DIST}-amd64-sbuild"
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


