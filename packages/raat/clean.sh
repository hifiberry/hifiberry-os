#!/bin/bash

# Clean up build artifacts
PACKAGE="hifiberry-raat"
BUILD_DIR="/tmp/${PACKAGE}-build"

echo "Cleaning up build artifacts for $PACKAGE"

# Remove build directory
rm -rf "$BUILD_DIR"

# Remove cloned repository
rm -rf src/raat

# Remove any temp files
rm -f *.deb *.changes *.buildinfo *.tar.gz

# Remove old Docker build artifacts
rm -rf out raat-docker-build/raat

# Clean up .pyc files and __pycache__ directories
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true

echo "Cleanup completed"
