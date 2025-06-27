#!/bin/bash

# Clean up build artifacts
PACKAGE="python3-xmltodict"
BUILD_DIR="/tmp/${PACKAGE}-build"

echo "Cleaning up build artifacts for $PACKAGE"

# Remove build directory
rm -rf "$BUILD_DIR"

# Remove any temp files
rm -f *.deb *.changes *.buildinfo *.tar.gz
rm -rf xmltodict-* build dist deb_dist *.egg-info

# Clean up .pyc files and __pycache__ directories
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

echo "Cleanup completed"
