#!/bin/bash
#
# start-nqptp.sh - NQPTP startup script
# This script handles startup of NQPTP daemon for network clock synchronization
#

# Start NQPTP with verbose output
echo "Starting NQPTP daemon for network clock synchronization..."
exec /usr/bin/nqptp -v