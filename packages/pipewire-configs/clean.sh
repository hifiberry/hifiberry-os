#!/bin/bash

echo "Cleaning HiFiBerry PipeWire configs package build artifacts..."

# Remove built packages
rm -f *.deb *.dsc *.tar.* *.changes *.buildinfo *.build

# Clean debian build artifacts
cd src
if [ -d debian ]; then
    fakeroot debian/rules clean 2>/dev/null || true
fi
cd ..

echo "Clean completed."