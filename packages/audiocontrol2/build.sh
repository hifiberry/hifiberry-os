#!/bin/bash

set -e

# Define variables
REPO_URL="https://github.com/hifiberry/audiocontrol2"
REPO_DIR="audiocontrol2"
DEST_DIR="$HOME/packages"
VERSION_FILE="$REPO_DIR/ac2/version.py"

# Function to clean up build files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$REPO_DIR/deb_dist"
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Clone the repository if it doesn't exist
if [[ ! -d $REPO_DIR ]]; then
    echo "Cloning the repository..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "Repository already exists. Skipping clone and update."
fi

# Step 2: Extract the version dynamically
if [[ -f $VERSION_FILE ]]; then
    VERSION=$(python3 -c "import sys; sys.path.insert(0, '$REPO_DIR/ac2'); from version import VERSION; print(VERSION)" 2>/dev/null || echo "0.0.0")
    echo "Extracted version: $VERSION"
else
    echo "Version file not found at $VERSION_FILE. Defaulting version to 0.0.0."
    VERSION="0.0.0"
fi

# Step 3: Build the Debian package
echo "Building the Debian package..."
cd "$REPO_DIR"
export DEB_BUILD_OPTIONS="noautodbgsym"

# Ensure debian/compat does not exist
if [[ -f "debian/compat" ]]; then
    echo "Removing conflicting debian/compat file..."
    rm -f debian/compat
fi

# Clean previous builds
echo "Running clean step..."
fakeroot debian/rules clean || true

# Build the package
python3 setup.py --command-packages=stdeb.command bdist_deb

# Step 4: Copy .deb files to the destination
echo "Copying .deb files to $DEST_DIR..."
mkdir -p "$DEST_DIR"
find "deb_dist" -name '*.deb' ! -name '*dbgsym*.deb' -exec cp {} "$DEST_DIR" \;

# Step 5: Output the result
echo "Debian packages created and copied to: $DEST_DIR"
find "$DEST_DIR" -name '*.deb'

