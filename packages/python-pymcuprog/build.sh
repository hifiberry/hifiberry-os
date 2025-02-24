#!/bin/bash

# Define variables
PACKAGE="pymcuprog"
WHEEL_DIR="wheel_dir"
VERSION="3.17.3.45"
DEB_OUTPUT_DIR="output"
DEST_DIR="$HOME/packages"

# Function to clean up build files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$WHEEL_DIR" "$DEB_OUTPUT_DIR" *.egg-info
    echo "Cleanup completed."
}

# Check for --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Check if wheel2deb is installed
if ! command -v wheel2deb &> /dev/null
then
    echo "wheel2deb is not installed. Please install wheel2deb and try again."
    exit 1  # Abort if wheel2deb is not installed
fi

# Step 1: Create wheel directory and download the package from PyPI
mkdir -p "$WHEEL_DIR"
echo "Downloading $PACKAGE version $VERSION from PyPI..."
pip download $PACKAGE==$VERSION --no-deps --index-url https://pypi.org/simple --dest "$WHEEL_DIR"

# Change to wheel directory
cd "$WHEEL_DIR"

# Step 2: Convert the wheel to a Debian package using wheel2deb
echo "Converting the wheel to a Debian package using wheel2deb..."
wheel2deb

# Change to the directory where the Debian package was generated
cd "$DEB_OUTPUT_DIR"
# This is a bit of a hack, it removes everything
# except the directory with the debian package sources
rm *
cd *

# Step 3: Adjust the control file
CONTROL_FILE="debian/control"
if [ -f "$CONTROL_FILE" ]; then
    # Adjust dependencies and architecture in the control file
    sed -i 's/python3-pyserial/python3-serial/g' "$CONTROL_FILE"
    sed -i 's/python3-pyyaml/python3-yaml/g' "$CONTROL_FILE"
    sed -i 's/python3-pyedbglib.*,//g'  "$CONTROL_FILE"
    sed -i 's/Architecture: all/Architecture: arm64/g' "$CONTROL_FILE"
    cat "$CONTROL_FILE"
    # Remove distribution suffix if present
    dch -r "" --force-distribution --newversion $VERSION-1
else
    echo "Cannot find Debian control file, aborting."
    exit 1
fi

# Step 4: Build the Debian package
echo "Building the Debian package..."
debuild -us -uc  # Build the package without signing it

# Step 5: Copy the generated .deb files to the destination directory
echo "Copying .deb files to $DEST_DIR..."
mkdir -p "$DEST_DIR"
export DEST_DIR
cd ..
find . -name '*.deb' -exec bash -c 'debfile="$1"; newfile="${debfile//~w2d0_/}"; echo Copy $debfile to $DEST_DIR/$newfile; cp "$debfile" "$DEST_DIR/$newfile"' _ {} \;

# Step 6: Output the result
if [ -d "$DEST_DIR" ]; then
    echo "Debian packages for $PACKAGE have been created and copied to: $DEST_DIR"
    find "$DEST_DIR" -name '*.deb'
else
    echo "No Debian package was created."
fi


