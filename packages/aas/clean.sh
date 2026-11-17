#!/bin/bash
cd "$(dirname "$0")"
rm -rf aas
rm -f aas_*.deb aas_*.buildinfo aas_*.changes libasound2-plugin-aas_*.deb
echo "Cleaned up aas build artifacts."
