#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="autorec"
DEB_PACKAGE="hifiberry-autorec"
REPO_URL="https://github.com/hifiberry/autorec"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE"
    rm -f ${DEB_PACKAGE}*.build ${DEB_PACKAGE}*.changes ${DEB_PACKAGE}*.dsc ${DEB_PACKAGE}*.deb ${DEB_PACKAGE}*.buildinfo ${DEB_PACKAGE}*.tar.gz
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Clone or update the GitHub repository
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    cd "$PACKAGE"
    git pull
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
    cd "$PACKAGE"
fi

# Step 2: Build Debian package using dpkg-buildpackage
echo "Building $DEB_PACKAGE Debian package..."
dpkg-buildpackage -us -uc -b

# Step 3: Move built packages back to package directory
cd ..
mv ${DEB_PACKAGE}*.deb . 2>/dev/null || true
mv ${DEB_PACKAGE}*.build . 2>/dev/null || true
mv ${DEB_PACKAGE}*.buildinfo . 2>/dev/null || true
mv ${DEB_PACKAGE}*.changes . 2>/dev/null || true

echo "Package build completed."
echo "Package: ${DEB_PACKAGE}*.deb"
