#!/bin/bash
set -e

cd "$(dirname "$0")"

rm -f ./*.deb ./*.changes ./*.buildinfo ./*.dsc ./*.tar.* ./*.build
rm -f ../hifiberry-acr-webmcp_*.deb ../hifiberry-acr-webmcp_*.changes ../hifiberry-acr-webmcp_*.buildinfo

cd src
rm -rf debian/.debhelper debian/debhelper-build-stamp debian/files debian/hifiberry-acr-webmcp debian/hifiberry-acr-webmcp.substvars

echo "Cleaned hifiberry-acr-webmcp build artifacts."
