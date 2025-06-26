#!/bin/bash

set -e

# Clean up function
function clean() {
    echo "Cleaning up build artifacts..."
    rm -rf src/build-area/
    rm -f src/../*.deb src/../*.changes src/../*.buildinfo src/../*.dsc
    echo "Cleanup complete."
}

# Build function using sbuild
function build_package() {
    echo "Building package with sbuild..."
    
    # Change to src directory where debian/ is located
    cd src
    
    # Make sure debian/rules is executable
    chmod +x debian/rules
    
    # Use sbuild to build the package
    sbuild --chroot-mode=unshare --no-clean-source
    
    # Go back to parent directory
    cd ..
    
    echo "Package build completed."
    echo "Built packages:"
    ls -la src/../*.deb 2>/dev/null || echo "No .deb files found"
}

# Main logic
case "$1" in
    --clean)
        clean
        ;;
    *)
        build_package
        ;;
esac

