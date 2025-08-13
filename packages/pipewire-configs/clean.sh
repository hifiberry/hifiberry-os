#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

echo "Cleaning hifiberry-pipewire-configs build artifacts in $SCRIPT_DIR ..."

# Top-level build outputs (produced by dpkg-buildpackage run in src/)
rm -f "$SCRIPT_DIR"/hifiberry-pipewire-configs_*.deb || true
rm -f "$SCRIPT_DIR"/hifiberry-pipewire-configs_*.changes || true
rm -f "$SCRIPT_DIR"/hifiberry-pipewire-configs_*.buildinfo || true
rm -f "$SCRIPT_DIR"/hifiberry-pipewire-configs_*.dsc || true
rm -f "$SCRIPT_DIR"/hifiberry-pipewire-configs_*.tar.* || true

# In-tree debian helper state inside src
if [ -d "$SRC_DIR/debian" ]; then
	rm -rf "$SRC_DIR/debian/hifiberry-pipewire-configs" || true
	rm -rf "$SRC_DIR/debian/.debhelper" || true
	rm -f  "$SRC_DIR/debian/debhelper-build-stamp" || true
	rm -f  "$SRC_DIR/debian/files" || true
	# Preserve control/changelog, so don't wipe entire debian directory
fi

echo "Clean completed"
