#!/bin/bash

# Exit on any error
set -e

# Define variables
PACKAGE_NAME="hifiberry-tools"
VERSION="1.0.0"
REVISION="1"
ARCHITECTURE="all"  # Use "all" for architecture-independent packages
INSTALL_DIR="/usr/local/bin"
LINK_DIR="/opt/hifiberry/bin"
BUILD_DIR="$PACKAGE_NAME"
DEBIAN_DIR="$BUILD_DIR/DEBIAN"
TARGET_DIR="$BUILD_DIR$INSTALL_DIR"
LINK_TARGET_DIR="$BUILD_DIR$LINK_DIR"
CONTROL_FILE="$DEBIAN_DIR/control"
BIN_DIR="./bin"  # Directory containing the files to package
OUTPUT_DIR="$HOME/packages"
DEB_FILE="${PACKAGE_NAME}_${VERSION}-${REVISION}_${ARCHITECTURE}.deb"

# Cleanup function
clean() {
    echo "Cleaning up previous build files..."
    rm -rf "$BUILD_DIR"
    echo "Cleanup complete."
}

# Check for --clean argument
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Cleanup previous build files
clean

# Step 2: Create directory structure
echo "Creating directory structure..."
mkdir -p "$TARGET_DIR" "$DEBIAN_DIR" "$OUTPUT_DIR" "$LINK_TARGET_DIR"

# Step 3: Copy files to target directory
if [[ -d "$BIN_DIR" ]]; then
    echo "Copying files from $BIN_DIR to $INSTALL_DIR..."
    cp -r "$BIN_DIR/"* "$TARGET_DIR/"
else
    echo "Error: Source directory $BIN_DIR does not exist. Exiting."
    exit 1
fi

# Step 4: Make all files executable
echo "Making all files in $INSTALL_DIR executable..."
chmod -R 755 "$TARGET_DIR"

# Step 5: Create symbolic links in /opt/hifiberry/bin
echo "Creating symbolic links in $LINK_DIR..."
for file in "$TARGET_DIR"/*; do
    ln -sf "$INSTALL_DIR/$(basename "$file")" "$LINK_TARGET_DIR/"
done

# Step 6: Create control file
echo "Creating control file..."
cat > "$CONTROL_FILE" <<EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCHITECTURE
Maintainer: HiFiBerry <support@hifiberry.com>
Description: HiFiBerry tools
 A custom package to install HiFiBerry tools into /usr/local/bin and link them to /opt/hifiberry/bin.
EOF

# Step 7: Build the Debian package
echo "Building the Debian package..."
dpkg-deb --build "$BUILD_DIR" "$OUTPUT_DIR/$DEB_FILE"

# Step 8: Output result
echo "Debian package created: $OUTPUT_DIR/$DEB_FILE"

