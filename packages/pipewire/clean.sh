#!/bin/bash

set -e

echo "Cleaning PipeWire build artifacts..."

# Clean the source directory
if [ -d "src" ]; then
    cd src
    
    # Clean debian build artifacts
    rm -rf debian/.debhelper/
    rm -rf debian/hifiberry-pipewire/
    rm -rf debian/files
    rm -rf debian/*.substvars
    rm -rf debian/*.log
    rm -rf debian/tmp/
    
    # Clean downloaded sources
    rm -rf pipewire-source/
    rm -f *.tar.gz
    
    cd ..
fi

# Clean output directory
rm -rf out/

# Clean any package files in the root
rm -f *.deb
rm -f *.dsc
rm -f *.tar.*
rm -f *.changes
rm -f *.buildinfo

echo "Clean completed."
