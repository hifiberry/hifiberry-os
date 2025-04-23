#!/bin/bash

# Define the destination directory for the .deb packages
DEST_DIR=~/packages

# Create the destination directory if it doesn't already exist
mkdir -p "$DEST_DIR"

# Run dpkg-buildpackage to build the package
dpkg-buildpackage -us -uc

# Check if dpkg-buildpackage was successful
if [ $? -eq 0 ]; then
    echo "Package build successful, moving .deb files to $DEST_DIR"

    # Move all .deb files to the destination directory
    mv ../*.deb "$DEST_DIR"
else
    echo "Package build failed, no files moved."
    exit 1
fi

# Optional: Clean up any other artifacts that might have been created
rm -rf debian/debhelper-build-stamp  debian/files debian/testtools debian/testtools.substvars

echo "Build process complete."

