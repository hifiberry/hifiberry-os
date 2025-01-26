#!/bin/bash

set -e

# Define variables
REPO_URL="https://github.com/hifiberry/audiocontrol2"
REPO_DIR="audiocontrol2"
DEST_DIR="$HOME/packages"
VERSION_FILE="$REPO_DIR/ac2/version.py"
OVERRIDES_FILE="py3dist-overrides"
CONTROL_FILE="control"

# Function to clean up build files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$REPO_DIR/deb_dist"
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Clone or update the repository
if [[ ! -d $REPO_DIR ]]; then
    echo "Cloning the repository..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "Updating the repository..."
    cd "$REPO_DIR"
    git pull --rebase
    cd ..
fi

# Step 2: Extract the version dynamically
if [[ -f $VERSION_FILE ]]; then
    VERSION=$(python3 -c "import sys; sys.path.insert(0, '$REPO_DIR/ac2'); from version import VERSION; print(VERSION)" 2>/dev/null || echo "0.0.0")
    echo "Extracted version: $VERSION"
else
    echo "Version file not found at $VERSION_FILE. Defaulting version to 0.0.0."
    VERSION="0.0.0"
fi

# Step 3: Build the Debian package
echo "Building the Debian package..."
cd "$REPO_DIR"
export DEB_BUILD_OPTIONS="noautodbgsym"
python3 setup.py --command-packages=stdeb.command bdist_deb

# Step 4: Define DEB_DIR dynamically
DEB_DIR="$REPO_DIR/deb_dist/audiocontrol2-$VERSION/debian"

# Ensure DEB_DIR exists after the build step
if [[ ! -d $DEB_DIR ]]; then
    echo "Error: Debian directory $DEB_DIR does not exist after building. Exiting."
    exit 1
fi

# Step 5: Update debian/py3dist-overrides
echo "Creating or updating dependency overrides..."
cat > "$DEB_DIR/$OVERRIDES_FILE" <<EOF
dbus python3-dbus
mpd python3-mpd
socketio python3-socketio
EOF
echo "Dependency overrides updated in $DEB_DIR/$OVERRIDES_FILE."

# Step 6: Update version in debian/control
echo "Updating version in $DEB_DIR/$CONTROL_FILE..."
sed -i "s/^Version: .*/Version: $VERSION/" "$DEB_DIR/$CONTROL_FILE"

# Step 7: Copy .deb files to the destination
echo "Copying .deb files to $DEST_DIR..."
mkdir -p "$DEST_DIR"
find "deb_dist" -name '*.deb' ! -name '*dbgsym*.deb' -exec cp {} "$DEST_DIR" \;

# Step 8: Output the result
echo "Debian packages created and copied to: $DEST_DIR"
find "$DEST_DIR" -name '*.deb'

