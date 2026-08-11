#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

# Define variables
PACKAGE="input-processor"
DEB_PACKAGE="hifiberry-input-processor"
REPO_URL="https://github.com/hifiberry/input-processor.git"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build files..."
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
rm -f ../hifiberry-input-processor-dbgsym*.deb

# Step 3: Move built packages back to package directory
cd ..

echo "Package build completed."
echo "Built packages:"
ls -lh $DEB_PACKAGE*.deb
