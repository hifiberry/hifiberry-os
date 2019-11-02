#!/bin/bash
V=`cat /etc/hifiberry.version`

if [ "$V" -lt 20191201 ]; then
 echo "Version < 20191201, adding postgresql configuration to audiocontrol"
 echo
 FOUND=`cat /newroot/etc/audiocontrol2.conf | grep '\[postgres\]'`
 if [ "$FOUND" == "" ]; then
  echo >> /newroot/etc/audiocontrol2.conf
  echo '[postgres]' >> /newroot/etc/audiocontrol2.conf
  echo "audiocontrol2.conf done"
 else
  echo "Postgres already configured"
 fi
fi

