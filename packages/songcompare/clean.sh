#!/bin/bash
cd "$(dirname "$0")"
echo "Cleaning up songcompare build artifacts..."
rm -rf songcompare
rm -f hifiberry-songcompare_*
rm -f hifiberry-songcompare-*
echo "Cleaned up songcompare build artifacts."
