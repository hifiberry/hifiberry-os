#!/bin/bash

set -e

# Configuration
MPD_VERSION="0.24.4"
MPC_VERSION="0.35"
PACKAGE_NAME="hifiberry-mpd"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Construct full version string
FULL_VERSION="${MPD_VERSION}"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Print help message
function print_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help           Display this help message"
    echo ""
    echo "Use ./clean.sh to clean build artifacts"
}

# Build function using sbuild
function build_package() {
    echo "Building package with sbuild..."
    
    # Update version in changelog if different
    cd src
    sed -i "s/hifiberry-mpd ([^)]*)/hifiberry-mpd (${FULL_VERSION})/" debian/changelog
    
    # Make sure debian/rules is executable
    chmod +x debian/rules
    
    # Use sbuild to build the package
    sbuild --chroot-mode=unshare --no-clean-source --enable-network
    
    # Go back to parent directory
    cd ..
    
    echo "Package build completed."
    echo "Built packages:"
    ls -la src/../*.deb 2>/dev/null || echo "No .deb files found"
}

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# Main logic
build_package