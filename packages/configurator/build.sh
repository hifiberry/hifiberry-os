#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="configurator"
REPO_URL="https://github.com/hifiberry/configurator"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE" "$DEB_OUTPUT_DIR"
    echo "Cleanup completed."
}

# Check version consistency between _version.py and debian/changelog
check_version_consistency() {
    if [[ -f "configurator/_version.py" ]] && [[ -f "debian/changelog" ]]; then
        PYTHON_VERSION=$(grep -m1 '^__version__ = ' configurator/_version.py | sed 's/__version__ = "\([^"]*\)"/\1/')
        DEBIAN_VERSION=$(grep -m1 "^hifiberry-configurator (" "debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
        
        if [[ "$PYTHON_VERSION" != "$DEBIAN_VERSION" ]]; then
            echo "ERROR: Version mismatch detected!"
            echo "  _version.py version:      $PYTHON_VERSION"
            echo "  debian/changelog version: $DEBIAN_VERSION"
            echo ""
            echo "Please update configurator/_version.py to match debian/changelog"
            exit 1
        fi
        echo "Version check passed: $PYTHON_VERSION"
    else
        echo "Warning: Could not check version consistency (missing _version.py or debian/changelog)"
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
    cd "$PACKAGE"
    git pull
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
    cd "$PACKAGE"
fi

# Step 2: Check version consistency
echo "Checking version consistency..."
check_version_consistency

# Step 3: Build the Debian package
echo "Building the Debian package..."
chmod u+x ./build-deb.sh
./build-deb.sh
echo "Debian package build completed."

# Step 4: Clean up build artifacts (keep only .deb files)
echo "Cleaning up build artifacts..."
cd ..
rm -f *.build *.buildinfo *.changes *.dsc *.tar.gz
echo "Build artifacts cleaned up"
echo "Built packages:"
ls -lh *.deb
