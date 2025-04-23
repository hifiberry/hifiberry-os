#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="dsptoolkit"
REPO_URL="https://github.com/hifiberry/hifiberry-dsp"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"
UNIT_FILE="sigma-tcpserver.service"
UNIT_DESCRIPTION="SigmaTCP Server for HiFiBerry DSP"
EXEC_START="\$LOC"

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

# Step 2: Add stdeb configuration with dependencies
echo "Adding stdeb configuration for dependencies..."
cat > stdeb.cfg <<EOF
[DEFAULT]
Depends = python3-pyalsaaudio
EOF

# Step 5: Build the Debian package
echo "Building Debian package for $PACKAGE..."
python3 setup.py --command-packages=stdeb.command bdist_deb

# Step 6: Locate and copy the generated .deb files, excluding dbgsym
echo "Copying .deb files (excluding dbgsym) to $DEST_DIR..."
mkdir -p "$DEST_DIR"
find "$DEB_OUTPUT_DIR" -name '*.deb' ! -name '*dbgsym*.deb' -exec cp {} "$DEST_DIR" \;

# Step 7: Output the result
echo "Debian packages for $PACKAGE created and copied to: $DEST_DIR"
find "$DEST_DIR" -name '*.deb'

