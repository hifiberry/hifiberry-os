#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

if [ ! -f "$SRC_DIR/debian/changelog" ]; then
	echo "Error: changelog not found at $SRC_DIR/debian/changelog" >&2
	exit 1
fi

pushd "$SRC_DIR" >/dev/null
VERSION=$(dpkg-parsechangelog -S Version)
DIST=$(dpkg-parsechangelog -S Distribution)
echo "Building hifiberry-pipewire-configs version $VERSION for $DIST"

dpkg-buildpackage -us -uc -b
popd >/dev/null

echo "Build completed successfully (artifact parent directory: $SCRIPT_DIR)"
