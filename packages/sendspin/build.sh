#!/bin/bash
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE="sendspin"
REPO_URL="https://github.com/hifiberry/sendspin"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"

if [[ "$1" == "--clean" ]]; then
    rm -rf "$PACKAGE"
    rm -f hifiberry-sendspin_*.deb hifiberry-sendspin_*.buildinfo hifiberry-sendspin_*.changes
    exit 0
fi

if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE from $REPO_URL..."
    (cd "$PACKAGE" && git pull)
else
    echo "Cloning $PACKAGE from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

echo "Building the Debian package..."
chmod u+x "$PACKAGE/build.sh"
(cd "$PACKAGE" && ./build.sh)

# Collect the .deb next to this script
mv "$PACKAGE"/../hifiberry-sendspin_*.deb "$SCRIPT_DIR/" 2>/dev/null || \
  mv hifiberry-sendspin_*.deb "$SCRIPT_DIR/" 2>/dev/null || true
echo "Built packages:"
ls -lh "$SCRIPT_DIR"/hifiberry-sendspin_*.deb 2>/dev/null || echo "No packages found"
