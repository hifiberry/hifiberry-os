#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="acr"
REPO_URL="https://github.com/hifiberry/acr"
DEB_OUTPUT_DIR="deb_dist"
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

# Step 2: Create secrets.txt if it doesn't exist
if [ ! -f "secrets.txt" ]; then
  if [-f "~/secrets.txt" ]; then
    echo "Copying secrets.txt from ~/secrets.txt..."
    cp ~/secrets.txt secrets.txt
  else
    echo "Creating secrets.txt from secrets.txt.sample..."
    cp secrets.txt.sample secrets.txt
    echo "Please edit secrets.txt with your credentials."
  fi
else
    echo "secrets.txt already exists."
fi

# Step 3: Build the Debian package
echo "Building the Debian package..."
fromdos build.sh
chmod u+x ./build.sh
./build.sh
echo "Debian package build completed."
