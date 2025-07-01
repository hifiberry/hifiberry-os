#!/bin/bash

# Clean script for webui package
# Removes all build artifacts and downloaded source

set -e

echo "Cleaning up webui build artifacts..."

# Remove source directory contents
if [ -d "src/hbos-ui" ]; then
    echo "Removing hbos-ui source directory..."
    rm -rf src/hbos-ui
fi

# Remove build artifacts
echo "Removing build artifacts..."
rm -f src/*.deb
rm -f src/*.build*
rm -f src/*.changes
rm -f src/*.dsc
rm -f src/*.tar.*

echo "Webui cleanup completed."
