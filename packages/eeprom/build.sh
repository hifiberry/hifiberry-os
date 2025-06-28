#!/bin/bash

set -e

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
ls -la *.deb 2>/dev/null || echo "No .deb files found"

