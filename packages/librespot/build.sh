#!/bin/bash

set -e

# Configuration
VERSION="0.6.0"
VERSION_POSTFIX=3 # 1,2,3,... unset when VERSION increases to start from 0 again
COMMIT_ID="59381ccad38ed39037392f3d2d30bf0d9593ff56"  # Optional specific commit ID to use (overrides VERSION if set)
PACKAGE_NAME="hifiberry-librespot"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Construct full version string - append VERSION_POSTFIX if it exists
FULL_VERSION="${VERSION}"
if [ -n "${VERSION_POSTFIX}" ]; then
    FULL_VERSION="${VERSION}.${VERSION_POSTFIX}"
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Print help message
function print_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --commit-id ID   Specify a specific commit ID to build (overrides version)"
    echo "  --help           Display this help message"
    echo ""
    echo "Use ./clean.sh to clean build artifacts"
}

# Build function using sbuild
function build_package() {
    echo "Building package with sbuild..."
        
    # Update version in changelog if different
    cd src
    sed -i "s/hifiberry-librespot ([^)]*)/hifiberry-librespot (${FULL_VERSION})/" debian/changelog
    
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
        --commit-id)
            COMMIT_ID="$2"
            shift 2
            ;;
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

