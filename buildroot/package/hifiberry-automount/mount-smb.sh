#!/bin/bash
BASEDIR=/data/library/music
for m in `cat /etc/smbmounts.conf | grep -v ^#`; do
  dir=`echo $m | awk -F, '{print $1}'`
  if [ ! -d $BASEDIR/$dir ]; then
    mkdir -p $BASEDIR/$dir
  fi
  mountcmd=`echo $m | awk -F, '{print "mount -t cifs -o user=" $3 ",password=" $4 " " $2 " /data/library/music/" $1}'`
  ${mountcmd}
done
if [ -x /opt/hifiberry/bin/update-mpd-db ]; then
 /opt/hifiberry/bin/update-mpd-db &
fi
