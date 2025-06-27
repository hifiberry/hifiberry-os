#!/bin/bash

# Clean up build artifacts
PACKAGE="python3-pyedbglib"
BUILD_DIR="/tmp/${PACKAGE}-build"

echo "Cleaning up build artifacts for $PACKAGE"

# Remove build directory
rm -rf "$BUILD_DIR"

# Remove cloned repository
rm -rf pyedbglib

# Remove any temp files
rm -f *.deb *.changes *.buildinfo *.tar.gz

echo "Cleanup completed"
