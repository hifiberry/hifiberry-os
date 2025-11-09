#!/bin/bash
cd `dirname $0`

echo "Cleaning up SongRec build artifacts..."

# Remove cloned repository
rm -rf songrec

# Remove all build artifacts
rm -rf songrec-*
rm -f songrec_*.deb
rm -f songrec_*.build
rm -f songrec_*.changes
rm -f songrec_*.dsc
rm -f songrec_*.buildinfo
rm -f songrec_*.tar.gz
rm -f songrec_*.tar.xz

echo "Cleaned up SongRec build artifacts."
