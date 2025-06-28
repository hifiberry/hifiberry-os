#!/bin/bash

# Clean up build artifacts
SCRIPT_DIR="$(dirname $(realpath $0))"
BUILD_DIR="/tmp/hifiberry-shairport-build"

echo "Cleaning up build artifacts..."

# Remove build directory
rm -rf "$BUILD_DIR"

# Remove package files from script directory
rm -f "$SCRIPT_DIR"/*.deb
rm -f "$SCRIPT_DIR"/*.changes
rm -f "$SCRIPT_DIR"/*.buildinfo
rm -f "$SCRIPT_DIR"/*.dsc
rm -f "$SCRIPT_DIR"/*.tar.gz
rm -f "$SCRIPT_DIR"/*.tar.xz

echo "Cleanup complete"
