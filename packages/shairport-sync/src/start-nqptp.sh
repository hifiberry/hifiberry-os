#!/bin/bash
#
# start-nqptp.sh - NQPTP startup script with user validation
# This script handles startup of NQPTP daemon for network clock synchronization
#

# User validation check
# Allow running as root, or as the user specified in /etc/hifiberry.user
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "root" ]; then
    if [ -f "/etc/hifiberry.user" ]; then
        AUTHORIZED_USER=$(cat /etc/hifiberry.user 2>/dev/null | tr -d '\n\r ')
        if [ "$CURRENT_USER" != "$AUTHORIZED_USER" ]; then
            echo "Error: not starting nqptp, this should run as user $AUTHORIZED_USER"
            exit 0
        fi
    else
        echo "Error: not starting nqptp, /etc/hifiberry.user not found and not running as root"
        exit 0
    fi
fi

# Start NQPTP with verbose output
echo "Starting NQPTP daemon for network clock synchronization..."
exec /usr/bin/nqptp -v