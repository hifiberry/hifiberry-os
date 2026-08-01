#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="hifiberry-auth"
REPO_URL="https://github.com/hifiberry/hifiberry-auth"

# Function to clean up build and downloaded files
clean() {
    ./clean.sh
}

# Check version consistency between setup.py and debian/changelog
check_version_consistency() {
    if [[ -f "setup.py" ]] && [[ -f "debian/changelog" ]]; then
        SETUP_VERSION=$(grep -m1 '^\s*version=' setup.py | sed 's/.*version="\([^"]*\)".*/\1/')
        DEBIAN_VERSION=$(grep -m1 "^hifiberry-auth (" "debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')

        if [[ "$SETUP_VERSION" != "$DEBIAN_VERSION" ]]; then
            echo "ERROR: Version mismatch detected!"
            echo "  setup.py version:         $SETUP_VERSION"
            echo "  debian/changelog version: $DEBIAN_VERSION"
            echo ""
            echo "Please update setup.py to match debian/changelog"
            exit 1
        fi
        echo "Version check passed: $SETUP_VERSION"
    else
        echo "Warning: Could not check version consistency (missing setup.py or debian/changelog)"
    fi
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Clone or update the GitHub repository
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    git -C "$PACKAGE" pull
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

cd "$PACKAGE"

# Step 2: Check version consistency
echo "Checking version consistency..."
check_version_consistency

# Step 3: Build the Debian package
echo "Building the Debian package..."

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi

sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    --enable-network \
    $DIST_ARG \
    --verbose

echo "Debian package build completed."

# Step 4: Clean up build artifacts (keep only .deb files)
cd ..
echo "Cleaning up build artifacts..."
rm -f *.build *.buildinfo *.changes *.dsc *.tar.xz *.tar.gz
echo "Build artifacts cleaned up"
echo "Built packages:"
ls -lh *.deb
