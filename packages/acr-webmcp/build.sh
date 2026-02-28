#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building hifiberry-acr-webmcp package..."

cd src
dpkg-buildpackage -us -uc -b
cd ..

mv -f src/*.deb src/*.changes src/*.buildinfo . 2>/dev/null || true

echo "Build completed."
