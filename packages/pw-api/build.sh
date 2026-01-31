#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="speakereq"
REPO_URL="https://github.com/hifiberry/speakereq"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE"
    rm -f $PACKAGE*.build $PACKAGE*.changes $PACKAGE*.dsc $PACKAGE*.deb $PACKAGE*.buildinfo $PACKAGE*.tar.gz
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

# Step 2: Build Debian package using make deb
echo "Building $PACKAGE Debian package..."
make deb

# Remove debug symbols package
rm -f ../$PACKAGE-dbgsym*.deb

# Step 3: Move built packages back to package directory
cd ..
mv $PACKAGE_*.deb . 2>/dev/null || true
mv $PACKAGE_*.build . 2>/dev/null || true
mv $PACKAGE_*.buildinfo . 2>/dev/null || true
mv $PACKAGE_*.changes . 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -la *.deb 2>/dev/null || echo "No .deb files found"
