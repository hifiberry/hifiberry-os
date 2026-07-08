#!/bin/bash
cd "$(dirname "$0")"
rm -rf sendspin
rm -f hifiberry-sendspin_*.deb hifiberry-sendspin_*.buildinfo hifiberry-sendspin_*.changes
echo "Cleaned up sendspin build artifacts."
