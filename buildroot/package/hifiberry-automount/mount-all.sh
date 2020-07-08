#!/bin/sh

for d in {a..z}; do 
    if [ -b /dev/sd$d ]; then
        echo "mounting /dev/sd$d"
        /opt/hifiberry/bin/mount-usb.sh add sd$d norescan
    fi
done

