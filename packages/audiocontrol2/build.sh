#!/bin/bash

set -e

# Define variables
REPO_URL="https://github.com/hifiberry/audiocontrol2"
REPO_DIR="audiocontrol2"
DEST_DIR="$HOME/packages"
VERSION_FILE="$REPO_DIR/ac2/version.py"

cd "$(dirname "$0")"
MYDIR=$(pwd)

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
export DEB_BUILD_OPTIONS=nocheck
python3 setup.py --command-packages=stdeb.command bdist_deb

# Step 4: Modify dependencies in the .deb file
echo "Modifying dependencies in the .deb file..."
DEB_FILE=$(find "deb_dist" -name '*.deb' ! -name '*dbgsym*.deb' | head -n 1)
if [[ -z "$DEB_FILE" ]]; then
    echo "Error: No .deb file found in deb_dist."
    exit 1
fi

TEMP_DIR=$(mktemp -d)
dpkg-deb -R "$DEB_FILE" "$TEMP_DIR"

CONTROL_FILE="$TEMP_DIR/DEBIAN/control"
if [[ -f "$CONTROL_FILE" ]]; then
    echo "Editing control file: $CONTROL_FILE"
    # Add additional dependencies to the Depends field
    sed -i 's/^Depends: /Depends: python3-dbus, python3-mpd, python3-smbus, python3-alsaaudio, /' "$CONTROL_FILE"
else
    echo "Error: Control file not found in $DEB_FILE."
    exit 1
fi

# Repack the .deb file
MODIFIED_DEB_FILE="$DEST_DIR/$(basename "$DEB_FILE")"
dpkg-deb -b "$TEMP_DIR" "$MODIFIED_DEB_FILE"
rm -rf "$TEMP_DIR"

# Step 5: Copy the modified .deb file to the destination
echo "Copying modified .deb file to $DEST_DIR..."
mkdir -p "$DEST_DIR"
echo "Modified package: $MODIFIED_DEB_FILE"

# Build systemd/config package
cd "$MYDIR"
./build-audiocontrol.sh

