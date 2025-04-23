#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="xmltodict"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"
VERSION="latest"  # Change to a specific version if needed

# Function to clean up build files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$PACKAGE-"* build dist deb_dist *.egg-info
    echo "Cleanup completed."
}

# Check for --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Download the source package from PyPI
if [ "$VERSION" == "latest" ]; then
    echo "Downloading the latest version of $PACKAGE from PyPI..."
    pip download $PACKAGE --no-binary :all: --no-deps
else
    echo "Downloading $PACKAGE version $VERSION from PyPI..."
    pip download $PACKAGE==$VERSION --no-binary :all: --no-deps
fi

# Step 2: Extract the source package
echo "Extracting the source package..."
TAR_FILE=$(ls $PACKAGE-*.tar.gz)
tar -xvzf "$TAR_FILE"
SRC_DIR=$(basename "$TAR_FILE" .tar.gz)
cd "$SRC_DIR"

# Step 3: Clean up .pyc files
echo "Cleaning up .pyc files..."
find . -name "*.pyc" -exec rm -f {} +
find . -name "__pycache__" -exec rm -rf {} +

# Step 4: Build the Debian package
echo "Building the Debian package for $PACKAGE..."
python3 setup.py --command-packages=stdeb.command bdist_deb

# Step 5: Locate and copy the generated .deb files
echo "Copying .deb files to $DEST_DIR..."
mkdir -p "$DEST_DIR"
find "$DEB_OUTPUT_DIR" -name '*.deb' -exec cp {} "$DEST_DIR" \;

# Step 6: Output the result
echo "Debian packages for $PACKAGE have been created and copied to: $DEST_DIR"
find "$DEST_DIR" -name '*.deb'

