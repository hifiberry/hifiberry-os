#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="songrec"
REPO_URL="https://github.com/marin-m/SongRec"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE" songrec-* songrec_*
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Clone or update the GitHub repository
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    cd "$PACKAGE"
    # Fetch all tags and updates
    git fetch --all --tags
    cd ..
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

# Copy our custom debian directory to the source
echo "Copying debian packaging files..."
cp -r debian "$PACKAGE/"

cd "$PACKAGE"

# Version consistency check
echo "Checking version consistency..."
CHANGELOG_VERSION=$(head -n 1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
echo "Changelog version: $CHANGELOG_VERSION"

if [ -z "$CHANGELOG_VERSION" ]; then
    echo "Error: Could not extract version from debian/changelog"
    exit 1
fi

# Checkout the correct version tag if specified
if [ -n "$CHANGELOG_VERSION" ]; then
    echo "Checking out version tag $CHANGELOG_VERSION..."
    if git rev-parse "refs/tags/$CHANGELOG_VERSION" >/dev/null 2>&1; then
        git checkout "$CHANGELOG_VERSION"
        echo "Checked out tag $CHANGELOG_VERSION"
    else
        echo "Warning: Tag $CHANGELOG_VERSION not found, using current HEAD"
    fi
fi

echo "Version check passed: $CHANGELOG_VERSION"

# Remove watch file if it exists (not needed for native packages)
rm -f debian/watch

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi

# Build using sbuild
echo "Building with sbuild..."
sbuild --chroot-mode=unshare --enable-network --no-clean-source $DIST_ARG

cd ..

# Clean up the debian directory from the git submodule
rm -rf "$PACKAGE/debian"

# Clean up build artifacts except the final .deb package
echo "Cleaning up build artifacts..."
find . -maxdepth 1 -name "*.build" -delete
find . -maxdepth 1 -name "*.buildinfo" -delete
find . -maxdepth 1 -name "*.changes" -delete
find . -maxdepth 1 -name "*.dsc" -delete
find . -maxdepth 1 -name "*.tar.gz" -delete
find . -maxdepth 1 -name "*.tar.xz" -delete

# Keep only the most recent .deb file
LATEST_DEB=$(ls -t songrec_*.deb 2>/dev/null | head -1)
if [ -n "$LATEST_DEB" ]; then
    # Remove all .deb files except the latest one
    ls -t songrec_*.deb | tail -n +2 | xargs -r rm -f
    echo "Kept latest package: $LATEST_DEB"
fi

# Show the package
echo "Package created:"
ls -lh songrec_*.deb 2>/dev/null || ls -lh *.deb

echo "Build completed successfully!"
