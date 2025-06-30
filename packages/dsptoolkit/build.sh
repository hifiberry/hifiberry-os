#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="hifiberry-dsp"
REPO_URL="https://github.com/hifiberry/hifiberry-dsp"
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
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    cd "$PACKAGE"
    git pull
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
    cd "$PACKAGE"
fi

# Step 1.5: Version consistency check
echo "Checking version consistency..."
CHANGELOG_VERSION=$(head -n 1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
echo "Changelog version: $CHANGELOG_VERSION"

if [ -z "$CHANGELOG_VERSION" ]; then
    echo "Error: Could not extract version from debian/changelog"
    exit 1
fi

echo "Version check passed: $CHANGELOG_VERSION"

# Remove watch file if it exists (not needed for native packages)
rm -f debian/watch

# Step 2: Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi

# Step 3: Build using sbuild
sbuild --chroot-mode=unshare --no-clean-source $DIST_ARG
cd ..

# Step 4: Show the package
echo "Package created:"
ls *deb
