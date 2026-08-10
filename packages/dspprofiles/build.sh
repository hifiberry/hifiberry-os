#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then 
    source "$_CC_ENV"
else 
    echo "Not using cross-compilation (${_CC_ENV} does not exist)"
fi

SCRIPT_DIR="$(dirname $(realpath $0))"
DSP_PROFILES_URL="https://github.com/hifiberry/dspprofiles"
DSP_PROFILES_CHECKOUT="$SCRIPT_DIR/dspprofiles"
PACKAGE="dspprofiles"

BUILD_DIR="/tmp/${PACKAGE}-build"

# Prepare build directory
echo "Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "DSP Profiles build script"

# Function to update or clone dspprofiles
update_dspprofiles() {
    echo "Updating DSP profiles..."
    if [[ -d "$DSP_PROFILES_CHECKOUT/.git" ]]; then
        echo "Updating dspprofiles from $DSP_PROFILES_URL..."
        cd "$DSP_PROFILES_CHECKOUT"
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
                echo "Please resolve conflicts manually"
            fi
        fi
        cd "$SCRIPT_DIR"
    else
        echo "Cloning dspprofiles from $DSP_PROFILES_URL..."
        git clone "$DSP_PROFILES_URL" "$DSP_PROFILES_CHECKOUT"
    fi
    echo "DSP profiles updated successfully"
}

# Update or clone the repository
update_dspprofiles

# Check if the checkout has its own build script
if [[ -f "$DSP_PROFILES_CHECKOUT/build.sh" ]]; then
    echo "Found build script in dspprofiles checkout, executing it..."
    cd "$DSP_PROFILES_CHECKOUT"
    chmod +x build.sh
    ./build.sh "$@"
    cd "$SCRIPT_DIR"
    
    # Copy any generated packages back to the parent directory
    if ls "$DSP_PROFILES_CHECKOUT"/*.deb 1> /dev/null 2>&1; then
        echo "Copying generated packages..."
        cp "$DSP_PROFILES_CHECKOUT"/*.deb "$SCRIPT_DIR/"
        echo "Packages copied to $SCRIPT_DIR"
    fi
else
    echo "No build script found in dspprofiles checkout"
    echo "Available files:"
    ls -la "$DSP_PROFILES_CHECKOUT/"
fi

echo "DSP profiles build completed"
