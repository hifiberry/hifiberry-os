#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
PACKAGE_NAME="hifiberry-baseconfig"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="/tmp/build-${PACKAGE_NAME}"

echo "Building ${PACKAGE_NAME} package..."

# Ensure we have the source directory
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory $SRC_DIR not found!"
    exit 1
fi

# Clean and create build directory
rm -rf "$BUILD_DIR"
cp -r "$SRC_DIR" "$BUILD_DIR"

cd "$BUILD_DIR"

# Make sure debian/rules is executable
chmod +x debian/rules

# Build binary packages directly
echo "Building binary packages..."
dpkg-buildpackage -us -uc

# Move packages to script directory
cd ..
mv ${PACKAGE_NAME}_${VERSION}*.deb "${SCRIPT_DIR}/" 2>/dev/null || true
mv ${PACKAGE_NAME}_${VERSION}*.dsc "${SCRIPT_DIR}/" 2>/dev/null || true
mv ${PACKAGE_NAME}_${VERSION}*.tar.* "${SCRIPT_DIR}/" 2>/dev/null || true
mv ${PACKAGE_NAME}_${VERSION}*.changes "${SCRIPT_DIR}/" 2>/dev/null || true
mv ${PACKAGE_NAME}_${VERSION}*.buildinfo "${SCRIPT_DIR}/" 2>/dev/null || true

echo "Build completed successfully!"
echo "Packages built in ${SCRIPT_DIR}:"
cd "${SCRIPT_DIR}"
ls -la *${VERSION}*.deb 2>/dev/null || echo "No .deb files found"

