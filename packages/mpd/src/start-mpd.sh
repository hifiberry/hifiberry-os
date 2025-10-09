#!/bin/bash
#
# start-mpd.sh - MPD startup script with user validation
# This script handles startup of Music Player Daemon with user validation
#

# User validation check
# Allow running as root, or as the user specified in /etc/hifiberry.user
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "root" ]; then
    if [ -f "/etc/hifiberry.user" ]; then
        AUTHORIZED_USER=$(cat /etc/hifiberry.user 2>/dev/null | tr -d '\n\r ')
        if [ "$CURRENT_USER" != "$AUTHORIZED_USER" ]; then
            echo "Error: not starting mpd, this should run as user $AUTHORIZED_USER"
            exit 0
        fi
    else
        echo "Error: not starting mpd, /etc/hifiberry.user not found and not running as root"
        exit 0
    fi
fi

# Configure MPD (ensure user config exists and has proper mixer settings)
echo "Configuring MPD..."
/usr/bin/configure-mpd

# Start MPD with user configuration
echo "Starting MPD..."
exec /usr/bin/mpd --no-daemon "$HOME/etc/mpd.conf"