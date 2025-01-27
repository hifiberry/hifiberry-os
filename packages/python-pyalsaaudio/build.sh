#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="pyalsaaudio"
VERSION="0.11.0"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE-$VERSION.tar.gz" "$PACKAGE-$VERSION" "$DEB_OUTPUT_DIR"
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Download the specific version of the package from PyPI
echo "Downloading $PACKAGE version $VERSION from PyPI..."
pip download $PACKAGE==$VERSION --no-binary :all: --no-deps

# Step 2: Extract the source package
echo "Extracting source package..."
TAR_FILE=$(ls $PACKAGE-$VERSION.tar.gz)
tar -xvzf "$TAR_FILE"
SRC_DIR=$(basename "$TAR_FILE" .tar.gz)
cd "$SRC_DIR"

# Step 3: Build the Debian package without dbgsym
echo "Building Debian package for $PACKAGE version $VERSION without dbgsym..."
export DEB_BUILD_OPTIONS="noautodbgsym"
python3 setup.py --command-packages=stdeb.command bdist_deb

# Step 4: Modify the control file to add Replaces and Conflicts
echo "Modifying control file to add Replaces and Conflicts..."
DEB_CONTROL_DIR=$(find "$DEB_OUTPUT_DIR" -type d -name 'DEBIAN' | head -n 1)
if [[ -n "$DEB_CONTROL_DIR" ]]; then
    sed -i '/^Depends:/a Replaces: python3-alsaaudio\nConflicts: python3-alsaaudio' "$DEB_CONTROL_DIR/control"
fi

# Step 5: Repack the .deb file
echo "Repacking the .deb file with updated control file..."
DEB_FILE=$(find "$DEB_OUTPUT_DIR" -name '*.deb' ! -name '*dbgsym*.deb' | head -n 1)
dpkg-deb --build "$(dirname "$DEB_CONTROL_DIR")" "$DEB_FILE"

# Step 6: Locate and copy the generated .deb files, excluding dbgsym
echo "Copying .deb files (excluding dbgsym) to $DEST_DIR..."
mkdir -p "$DEST_DIR"
find "$DEB_OUTPUT_DIR" -name '*.deb' ! -name '*dbgsym*.deb' -exec cp {} "$DEST_DIR" \;

# Step 7: Output the result
echo "Debian packages for $PACKAGE version $VERSION created and copied to: $DEST_DIR"
find "$DEST_DIR" -name '*.deb'

