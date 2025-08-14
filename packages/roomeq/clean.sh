#!/bin/bash
set -e

# Clean script for roomeq package
cd "$(dirname "$0")/roomeq"
# Example clean command, adjust as needed
echo "Cleaning roomeq..."
# If there's a Makefile:
# make clean
# If it's Python:
# python3 setup.py clean
# Add cleaning steps here
echo "Clean complete."
