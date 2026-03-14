#!/bin/bash

set -e

echo "Building HiFiBerry PipeWire configs package..."

cd src

# Build the package
dpkg-buildpackage -us -uc

cd ..

# Remove debug symbols package (though pipewire-configs shouldn't produce any)
rm -f *-dbgsym*.deb 2>/dev/null || true

echo "Build completed successfully!"
echo "Built packages:"
ls -la *.deb 2>/dev/null || echo "No .deb files found"