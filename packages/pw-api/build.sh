#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="pipewire-api"
REPO_URL="https://github.com/hifiberry/pipewire-api.git"

# Function to check version consistency
check_version_consistency() {
    echo "Checking version consistency..."
    
    # Get version from Cargo.toml
    local cargo_version=$(grep -E '^version\s*=\s*"[^"]*"' pipewire-api/Cargo.toml | head -1 | sed -E 's/^version\s*=\s*"([^"]*)"/\1/')
    
    # Get version from VERSION file
    local version_file=$(cat pipewire-api/VERSION | tr -d '\n')
    
    # Get version from debian/changelog (extract X.Y.Z from X.Y.Z-N format)
    local debian_version=$(head -1 pipewire-api/debian/changelog | sed -E 's/^[^(]*\(([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    
    echo "  Cargo.toml version:     $cargo_version"
    echo "  VERSION file:           $version_file"
    echo "  debian/changelog:       $debian_version"
    
    # Check if all versions match
    if [[ "$cargo_version" != "$debian_version" ]] || [[ "$version_file" != "$debian_version" ]]; then
        echo "ERROR: Version mismatch detected!"
        echo "  Cargo.toml:     $cargo_version"
        echo "  VERSION file:   $version_file"
        echo "  debian/changelog: $debian_version"
        echo "Please update all version files to match debian/changelog"
        exit 1
    fi
    
    echo "✓ All versions consistent: $debian_version"
}

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$PACKAGE"
    rm -f $PACKAGE*.build $PACKAGE*.changes $PACKAGE*.dsc $PACKAGE*.deb $PACKAGE*.buildinfo $PACKAGE*.tar.gz
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

# Check version consistency before building
cd ..
check_version_consistency

# Step 2: Build Debian package using make deb
echo "Building $PACKAGE Debian package..."
cd "$PACKAGE"
make deb

# Remove debug symbols packages
rm -f ../pipewire-api-dbgsym*.deb

# Step 3: Move built packages back to package directory
cd ..
mv pipewire-api_*.deb . 2>/dev/null || true
mv pipewire-api_*.build . 2>/dev/null || true
mv pipewire-api_*.buildinfo . 2>/dev/null || true
mv pipewire-api_*.changes . 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -la *.deb 2>/dev/null || echo "No .deb files found"
