#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

# Define variables
PACKAGE="hifiberry-shairport"
REPO_URL="https://github.com/hifiberry/hifiberry-shairport"
DEST_DIR="$HOME/packages"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE"
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

# Step 2: Build the Debian package
echo "Building the Debian package..."
chmod u+x ./build-deb.sh
./build-deb.sh
echo "Debian package build completed."

# Step 3: Clean up build artifacts (keep only .deb files)
echo "Cleaning up build artifacts..."
cd ..
rm -f *.build *.buildinfo *.changes *.dsc *.tar.gz
echo "Build artifacts cleaned up"
echo "Built packages:"
ls -lh *.deb
