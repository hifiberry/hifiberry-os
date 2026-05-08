#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="hbos-bluetooth"
REPO_URL="https://github.com/hifiberry/hbos-bluetooth"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE" "$DEB_OUTPUT_DIR"
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Clone or update the GitHub repository
# Pull is best-effort — when the remote is unreachable (offline build, fork
# without push access, …) we still want to build with the local checkout.
# Set NO_PULL=1 to skip the pull entirely (e.g. when iterating with local
# uncommitted changes that haven't been pushed yet).
if [[ -d "$PACKAGE/.git" ]]; then
    cd "$PACKAGE"
    if [[ "${NO_PULL:-0}" != "1" ]]; then
        echo "Updating $PACKAGE source from $REPO_URL..."
        git pull || echo "Warning: git pull failed, continuing with local checkout"
    else
        echo "NO_PULL set, skipping git pull for $PACKAGE"
    fi
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
