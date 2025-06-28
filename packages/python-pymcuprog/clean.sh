#!/bin/bash

# Clean up build artifacts
PACKAGE="python3-pymcuprog"
BUILD_DIR="/tmp/${PACKAGE}-build"

echo "Cleaning up build artifacts for $PACKAGE"

# Remove build directory
rm -rf "$BUILD_DIR"

# Remove any temp files
rm -f *.deb *.changes *.buildinfo *.tar.gz *.whl
rm -rf wheel_dir output *.egg-info

echo "Cleanup completed"
