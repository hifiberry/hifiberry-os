#!/bin/bash

# Exit on error
set -e

# Define variables
SOURCE_PACKAGE="acr"
REPO_URL="https://github.com/hifiberry/acr"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"

# Extract version from debian/changelog after cloning/updating
extract_version() {
    if [[ -f "debian/changelog" ]]; then
        VERSION=$(grep -m1 "^hifiberry-audiocontrol (" "debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
        if [[ -z "$VERSION" ]]; then
            echo "Error: Could not extract version from debian/changelog"
            exit 1
        fi
        PACKAGE="hifiberry-audiocontrol-$VERSION"
        echo "Detected version: $VERSION"
        echo "Package directory will be: $PACKAGE"
    else
        echo "Error: debian/changelog not found at debian/changelog"
        exit 1
    fi
}

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$SOURCE_PACKAGE" hifiberry-audiocontrol-* "$DEB_OUTPUT_DIR"
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then

    clean
    exit 0
fi

# Step 1: Clone or update the GitHub repository
if [[ -d "$SOURCE_PACKAGE/.git" ]]; then
    echo "Updating $SOURCE_PACKAGE source from $REPO_URL..."
    cd "$SOURCE_PACKAGE"
    # Stash any local changes before pulling
    if git diff --quiet && git diff --cached --quiet; then
        echo "No local changes detected, pulling updates..."
        git pull
    else
        echo "Local changes detected, stashing before pull..."
        git stash push -m "Build script auto-stash $(date)"
        git pull
        echo "Attempting to restore stashed changes..."
        if git stash pop; then
            echo "Successfully restored local changes"
        else
            echo "Warning: Conflicts detected when restoring changes"
            echo "Please resolve conflicts manually or use --clean to start fresh"
        fi
    fi
    # Extract version from changelog now that we're in the correct directory
    extract_version
    cd ..
else
    echo "Cloning $SOURCE_PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$SOURCE_PACKAGE"
    cd "$SOURCE_PACKAGE"
    # Extract version from changelog now that we're in the correct directory
    extract_version
    cd ..
fi

# Step 2: Create secrets.txt if it doesn't exist
cd "$SOURCE_PACKAGE"
if [ ! -f "secrets.txt" ]; then
  if [ -f "$HOME/secrets.txt" ]; then
    echo "Copying secrets.txt from $HOME/secrets.txt..."
    cp "$HOME/secrets.txt" secrets.txt
  else
    echo "Creating secrets.txt from secrets.txt.sample..."
    cp secrets.txt.sample secrets.txt
    echo "Please edit secrets.txt with your credentials."
  fi
else
    echo "secrets.txt already exists."
fi
cd ..

# Step 3: Prepare source directory with correct Debian package name
echo "Preparing source directory for Debian packaging..."
# Remove any existing package directory
rm -rf "$PACKAGE"
# Copy source to proper package directory name
cp -r "$SOURCE_PACKAGE" "$PACKAGE"
cd "$PACKAGE"

# Step 4: Build the Debian package
echo "Building the Debian package..."
fromdos build.sh
chmod u+x ./build.sh
# Check that we're in the right directory and call the ACR build script
if [ -f "./build.sh" ] && [ -f "./Cargo.toml" ]; then
    echo "Calling ACR build script from directory: $(pwd)"
    ./build.sh
else
    echo "Error: Not in correct ACR package directory or missing build files"
    echo "Current directory: $(pwd)"
    echo "Contents: $(ls -la)"
    exit 1
fi
echo "Debian package build completed."
