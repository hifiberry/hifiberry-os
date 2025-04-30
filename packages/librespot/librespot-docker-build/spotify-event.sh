#!/bin/bash
#
# spotify-event.sh - Event handler script for Librespot
# This script logs all received Spotify events to a log file
# and dumps track information when a track changes and all variables in JSON format
#

# Log file location
LOG_FILE="/tmp/spotify.log"
EVENT_PIPE="/var/run/librespot/event_pipe"

# Check if the pipe exists, if not create it and set permissions
if [ ! -p "$EVENT_PIPE" ]; then
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$EVENT_PIPE")"
    # Create the named pipe
    mkfifo "$EVENT_PIPE"
    # Set permissions: readable by group audio
    chmod 660 "$EVENT_PIPE"
    chown root:audio "$EVENT_PIPE"
fi

# Log timestamp, command line parameters, and event type
# echo "$(date): EVENT=$PLAYER_EVENT" >> "$LOG_FILE"

# Dump all player event variables in JSON format to the named pipe
# We do this in the background to avoid blocking if no reader is connected
{
    echo "{"
    echo "  \"timestamp\": \"$(date +%s)\","
    echo "  \"event\": \"$PLAYER_EVENT\","
    
    # Add all environment variables to JSON
    # Start with comma set to empty string for the first item
    comma=""
    
    # Loop through all environment variables
    env | sort | while IFS='=' read -r key value; do
        # Skip variables that start with underscore or are shell internals
        if [[ ! $key =~ ^[_] && ! $key =~ ^(BASH|HOSTNAME|HOME|PATH|PWD|SHELL|SHLVL|TERM|USER|LOGNAME|OLDPWD|LANG|LANGUAGE)$ ]]; then
            # Properly escape the value for JSON
            escaped_value=$(echo "$value" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g' | sed 's/\n/\\n/g')
            echo "  $comma\"$key\": \"$escaped_value\""
            comma=","
        fi
    done
    
    echo "}"
} > "$EVENT_PIPE" &

exit 0