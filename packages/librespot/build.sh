#!/bin/bash

set -e



# Building package with sbuild
echo "Building package with sbuild..."
    
cd src

# Make sure debian/rules is executable
chmod +x debian/rules

# Use sbuild to build the package
if [ -z "$DIST" ]; then
    sbuild --chroot-mode=unshare --no-clean-source --enable-network
else
    sbuild --chroot-mode=unshare --no-clean-source --enable-network --dist="$DIST"
fi

# Go back to parent directory
cd ..

echo "Package build completed."
echo "Built packages:"
ls -la src/../*.deb 2>/dev/null || echo "No .deb files found"

