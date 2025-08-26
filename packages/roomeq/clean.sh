#!/bin/bash
set -e

# Clean script for roomeq package
cd "$(dirname "$0")"
# Example clean command, adjust as needed
echo "Cleaning roomeq..."
rm -f roomeq_*.build roomeq_*.buildinfo roomeq_*.changes  roomeq_*.dsc  roomeq_*.tar.gz
echo "Clean complete."
