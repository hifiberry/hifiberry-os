#!/bin/bash
set -e

cd "$(dirname "$0")"

rm -f ./*.deb ./*.changes ./*.buildinfo ./*.dsc ./*.tar.* ./*.build

cd src
rm -rf debian/.debhelper debian/debhelper-build-stamp debian/files debian/hifiberry-acr-webmcp debian/hifiberry-acr-webmcp.substvars

echo "Cleaned hifiberry-acr-webmcp build artifacts."
