#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="dsptoolkit"
REPO_URL="https://github.com/hifiberry/hifiberry-dsp"
DEST_DIR="$HOME/packages"

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

# Step 2: Build using the script in the package
chmod ugo+x ./build*.sh
./build-docker.sh
cd ..

# Step 3: Show the package
echo "Package created:"
ls $PACKAGE/*deb
