#!/bin/sh
MOUNTED=`mount | grep mmcblk0p4`
if [ "$MOUNTED" != "" ]; then
 echo "already mounted"
 exit
fi

FSTYPE=`lsblk -f | grep mmcblk0p4 | awk '{print $2}'`
if [ "$FSTYPE" == "f2fs" ]; then
 echo "y" | fsck -p -y /dev/mmcblk0p4
else
 fsck -p -y /dev/mmcblk0p4
fi
mount /data

RES=$?

if [ "$RES" != 0 ]; then
 # it might have been mounted already in parallel
 sleep 5
 MOUNTED=`mount | grep mmcblk0p4`
 if [ "$MOUNTED" != "" ]; then
  echo "already mounted"
  exit
 fi
fi

