#!/bin/bash

set -e

echo "Cleaning MPD build artifacts..."

# Clean output directory
rm -rf out/

# Clean any package files in the root
rm -f *.deb
rm -f *.dsc
rm -f *.tar.*
rm -f *.changes
rm -f *.buildinfo

echo "Clean completed."
