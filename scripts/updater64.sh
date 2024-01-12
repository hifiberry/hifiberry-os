#!/bin/bash

touch /newroot/etc/quiet_start

V=`cat /etc/hifiberry.version`
if [ "$V" == "" ]; then
 V=0
fi
echo "Upgrading from version $V"
