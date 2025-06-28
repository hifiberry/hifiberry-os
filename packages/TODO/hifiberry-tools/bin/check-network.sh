#!/bin/bash

while : ; do
    # Check if eth0 or wlan0 has an IP address
    if ip addr show eth0 | grep -q inet || ip addr show wlan0 | grep -q inet; then
        break # Exit the loop if either interface has an IP address
    fi
    sleep 1
done

