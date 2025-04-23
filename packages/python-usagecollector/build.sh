#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="usagecollector"
REPO_URL="https://github.com/hifiberry/usagecollector"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"

# Function to clean up build files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$PACKAGE" build dist deb_dist *.egg-info
    echo "Cleanup completed."
}

# Check for --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Clone or update the GitHub repository
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    cd "$PACKAGE"
    git pull
    cd ..
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

# Step 2: Navigate to the source directory
cd "$PACKAGE"

# Step 3: Clean up previous build files
echo "Cleaning up .pyc files and __pycache__ directories..."
find . -name "*.pyc" -exec rm -f {} +
find . -name "__pycache__" -exec rm -rf {} +

# Step 4: Build the Debian package
echo "Building the Debian package for $PACKAGE (skipping tests)..."
export PYTHONDONTWRITEBYTECODE=1  # Disable .pyc creation
python3 setup.py --command-packages=stdeb.command bdist_deb

# Step 5: Locate and copy the generated .deb files
echo "Copying .deb files to $DEST_DIR..."
mkdir -p "$DEST_DIR"
find "$DEB_OUTPUT_DIR" -name '*.deb' -exec cp {} "$DEST_DIR" \;

# Step 6: Output the result
echo "Debian packages for $PACKAGE have been created and copied to: $DEST_DIR"
find "$DEST_DIR" -name '*.deb'

