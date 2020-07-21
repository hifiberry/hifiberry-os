#!/bin/sh
MOUNTED=`mount | grep mmcblk0p4`
if [ "$MOUNTED" != "" ]; then
 exit
fi

FSTYPE=`lsblk -f | grep mmcblk0p4 | awk '{print $2}'`
if [ "$FSTYPE" == "f2fs" ]; then
 echo "y" | fsck -p -y /dev/mmcblk0p4
else
 fsck -p -y /dev/mmcblk0p4
fi
mount /data
