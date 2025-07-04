#!/bin/bash
#
# spotify-event.sh - Event handler script for Librespot
# This script logs all received Spotify events to a log file
# and dumps track information when a track changes and all variables in JSON format
#

# Log file location
LOG_FILE="/tmp/spotify.log"
JSON_FILE="/tmp/spotifyevent.json"
JSON_PIPE="/var/lib/librespot/event_pipe"

# Log timestamp, command line parameters, and event type
echo "$(date): EVENT=$PLAYER_EVENT" >> "$LOG_FILE"

# Dump all player event variables in JSON format
generate_json() {
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
}

# Generate JSON once and store it
JSON_DATA=$(generate_json)

# Write to JSON file
echo "$JSON_DATA" > "$JSON_FILE"

# Also send JSON data to the named pipe if it exists
if [ -p "$JSON_PIPE" ]; then
    echo "$JSON_DATA" > "$JSON_PIPE"
fi


exit 0