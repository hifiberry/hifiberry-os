#!/bin/bash

# Define variables
PACKAGE="nowplaying-sdl"
DEB_OUTPUT_DIR="deb_dist"

# Function to clean up build and downloaded files
echo "Cleaning up build and downloaded files..."
rm -rf "$PACKAGE" "$DEB_OUTPUT_DIR"
rm -f nowplaying-sdl_*.deb nowplaying-sdl_*.buildinfo nowplaying-sdl_*.changes
echo "Cleanup completed."
