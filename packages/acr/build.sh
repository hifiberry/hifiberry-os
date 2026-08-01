#!/bin/bash

# Exit on error
set -e

# Define variables
SOURCE_PACKAGE="acr"
REPO_URL="https://github.com/hifiberry/acr"
DEB_OUTPUT_DIR="deb_dist"
DEST_DIR="$HOME/packages"

# Extract version from debian/changelog after cloning/updating
extract_version() {
    if [[ -f "debian/changelog" ]]; then
        VERSION=$(grep -m1 "^hifiberry-audiocontrol (" "debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
        if [[ -z "$VERSION" ]]; then
            echo "Error: Could not extract version from debian/changelog"
            exit 1
        fi
        PACKAGE="hifiberry-audiocontrol-$VERSION"
        echo "Detected version: $VERSION"
        echo "Package directory will be: $PACKAGE"
    else
        echo "Error: debian/changelog not found at debian/changelog"
        exit 1
    fi
}

# Check version consistency between Cargo.toml and debian/changelog
check_version_consistency() {
    if [[ -f "Cargo.toml" ]] && [[ -f "debian/changelog" ]]; then
        CARGO_VERSION=$(grep -m1 '^version = ' Cargo.toml | sed 's/version = "\([^"]*\)"/\1/')
        DEBIAN_VERSION=$(grep -m1 "^hifiberry-audiocontrol (" "debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
        
        if [[ "$CARGO_VERSION" != "$DEBIAN_VERSION" ]]; then
            echo "ERROR: Version mismatch detected!"
            echo "  Cargo.toml version:      $CARGO_VERSION"
            echo "  debian/changelog version: $DEBIAN_VERSION"
            echo ""
            echo "Please update Cargo.toml version to match debian/changelog"
            exit 1
        fi
        echo "Version check passed: $CARGO_VERSION"
    else
        echo "Warning: Could not check version consistency (missing Cargo.toml or debian/changelog)"
    fi
}

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$SOURCE_PACKAGE" hifiberry-audiocontrol-* "$DEB_OUTPUT_DIR"
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then

    clean
    exit 0
fi

# Clone or update the GitHub repository
if [[ -d "$SOURCE_PACKAGE/.git" ]]; then
    echo "Updating $SOURCE_PACKAGE source from $REPO_URL..."
    cd "$SOURCE_PACKAGE"
    # Stash any local changes before pulling
    if git diff --quiet && git diff --cached --quiet; then
        echo "No local changes detected, pulling updates..."
        git pull
    else
        echo "Local changes detected, stashing before pull..."
        git stash push -m "Build script auto-stash $(date)"
        git pull
        echo "Attempting to restore stashed changes..."
        if git stash pop; then
            echo "Successfully restored local changes"
        else
            echo "ERROR: restoring the stashed local changes hit a conflict in $(pwd)." >&2
            echo "The working tree now has conflict markers and the stash was kept." >&2
            echo "Refusing to build: a conflicted tree would package broken sources." >&2
            echo "" >&2
            echo "  git -C $(pwd) status          # see the conflicted files" >&2
            echo "  git -C $(pwd) stash list      # your changes are still here" >&2
            echo "" >&2
            echo "To build from upstream and keep the stash for later:" >&2
            echo "  git -C $(pwd) checkout HEAD -- <conflicted file>" >&2
            echo "Or discard the working copy entirely: ./build.sh --clean" >&2
            exit 1
        fi
    fi
    # Extract version from changelog now that we're in the correct directory
    extract_version
    check_version_consistency
    cd ..
else
    echo "Cloning $SOURCE_PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$SOURCE_PACKAGE"
    cd "$SOURCE_PACKAGE"
    # Extract version from changelog now that we're in the correct directory
    extract_version
    check_version_consistency
    cd ..
fi

# Refresh secrets.txt from $HOME/secrets.txt.
#
# This used to only run when secrets.txt was absent. A placeholder copy made
# from secrets.txt.sample (when $HOME/secrets.txt did not exist yet) therefore
# survived every later build: the checkout is only git-pulled, and secrets.txt
# is untracked. Builds then silently baked "your_lastfm_api_key_here" and
# "your-spotify-proxy-secret-here" into the binary, which the daemon happily
# sent to Last.fm ("Invalid API key") and to the Spotify OAuth proxy (401 ->
# 500 on /spotify/create_session). $HOME/secrets.txt now always wins.
cd "$SOURCE_PACKAGE"
if [ -f "$HOME/secrets.txt" ]; then
  echo "Copying secrets.txt from $HOME/secrets.txt..."
  cp "$HOME/secrets.txt" secrets.txt
elif [ ! -f "secrets.txt" ]; then
  echo "Creating secrets.txt from secrets.txt.sample..."
  cp secrets.txt.sample secrets.txt
  echo "Please edit secrets.txt with your credentials."
fi

# Never ship a build with sample credentials in it.
if cmp -s secrets.txt secrets.txt.sample; then
  echo "ERROR: secrets.txt is identical to secrets.txt.sample."
  echo "  The build would bake placeholder credentials into the binary and"
  echo "  Last.fm, Spotify and TheAudioDB would all fail at runtime."
  echo "  Put the real credentials in $HOME/secrets.txt and re-run."
  exit 1
fi
cd ..

# Remove build artefacts if they exist
RUST_BUILD_DIR="$SOURCE_PACKAGE/target"
if [ -d $RUST_BUILD_DIR ]; then
    echo "Removing existing Rust build directory: $RUST_BUILD_DIR"
    rm -rf "$RUST_BUILD_DIR"
else
    echo "No existing Rust build directory found."
fi

# Prepare source directory with correct Debian package name
echo "Preparing source directory for Debian packaging..."
# Remove any existing package directory
rm -rf "$PACKAGE"
# Copy source to proper package directory name
cp -r "$SOURCE_PACKAGE" "$PACKAGE"
cd "$PACKAGE"

# Build the Debian package
echo "Building the Debian package..."
fromdos build.sh
chmod u+x ./build.sh
# Check that we're in the right directory and call the ACR build script
if [ -f "./build.sh" ] && [ -f "./Cargo.toml" ]; then
    echo "Calling ACR build script from directory: $(pwd)"
    ./build.sh
else
    echo "Error: Not in correct ACR package directory or missing build files"
    echo "Current directory: $(pwd)"
    echo "Contents: $(ls -la)"
    exit 1
fi
echo "Debian package build completed."
