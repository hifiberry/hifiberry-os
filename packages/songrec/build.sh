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
    # Stash any local changes before pulling
    if git diff --quiet && git diff --cached --quiet; then
        echo "No local changes detected, pulling updates..."
        git pull
    else
        echo "Local changes detected, stashing before pull..."
        git stash push -m "Build script auto-stash $(date)"
        git pull
        echo "Attempting to restore stashed changes..."
        if git stash pop; then
            echo "Successfully restored local changes"
        else
            echo "Warning: Conflicts detected when restoring changes"
            echo "Please resolve conflicts manually or use --clean to start fresh"
        fi
    fi
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
    cd "$PACKAGE"
fi

# Check if debian directory exists, if not copy from packaging/ppa/
if [ ! -d "debian" ]; then
    if [ -d "packaging/ppa/debian" ]; then
        echo "Copying debian packaging from packaging/ppa/..."
        cp -r packaging/ppa/debian .
    else
        echo "Error: No debian/ directory found in the repository"
        echo "This package may need manual Debian packaging setup"
        exit 1
    fi
fi

# Update distribution in changelog from bionic to stable
if [ -f "debian/changelog" ]; then
    sed -i 's/) bionic;/) stable;/g' debian/changelog
fi

# Version consistency check
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
sbuild --chroot-mode=unshare --no-clean-source $DIST_ARG

cd ..

# Show the package
echo "Package created:"
ls -lh songrec_*.deb 2>/dev/null || ls -lh *.deb

echo "Build completed successfully!"
