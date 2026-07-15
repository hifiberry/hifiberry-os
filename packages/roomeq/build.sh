#!/bin/bash

# Exit on error
set -e

# Define variables
SOURCE_PACKAGE="roomeq"
REPO_URL="https://github.com/hifiberry/roomeq"

# Function to clean up build and downloaded files
clean() {
	echo "Cleaning up build and downloaded files..."
	rm -rf "$SOURCE_PACKAGE"
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
	cd ..
else
	echo "Cloning $SOURCE_PACKAGE source from $REPO_URL..."
	git clone "$REPO_URL" "$SOURCE_PACKAGE"
fi

# Build steps for roomeq
cd "$SOURCE_PACKAGE"
echo "Building roomeq..."
./build.sh
cd ..
rm roomeq-dbgsym*
echo "Build complete."
