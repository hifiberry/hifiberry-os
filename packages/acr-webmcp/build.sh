#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building hifiberry-acr-webmcp package..."

cd src
dpkg-buildpackage -us -uc -b
cd ..

mv -f ./*.deb ./*.changes ./*.buildinfo ../ 2>/dev/null || true

echo "Build completed."
