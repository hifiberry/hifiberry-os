#!/bin/sh
DEVNAME=mmcblk0p4
MOUNTED=`mount | grep $DEVNAME`
if [ "$MOUNTED" != "" ]; then
  echo "already mounted"
  exit
fi

FSTYPE=`lsblk -f | grep $DEVNAME | awk '{print $2}'`
if [ "$FSTYPE" == "f2fs" ]; then
  echo "y" | fsck -p -y /dev/$DEVNAME
else
  fsck -p -y /dev/$DEVNAME
fi
mount /dev/$DEVNAME /data

RES=$?

if [ "$RES" != 0 ]; then
  # it might have been mounted already in parallel
  sleep 10
  MOUNTED=`mount | grep $DEVNAME`
  if [ "$MOUNTED" != "" ]; then
    echo "already mounted"
    exit
  else
    echo "Couldn't mount /data"
    exit $RES
   fi 
fi

