#!/bin/bash
#
# spotify-event.sh - Event handler script for Librespot
# This script logs all received Spotify events to a log file
#

# Log file location
LOG_FILE="/tmp/spotify.log"

# Log timestamp and all parameters
echo "$(date): $@" >> "$LOG_FILE"

exit 0