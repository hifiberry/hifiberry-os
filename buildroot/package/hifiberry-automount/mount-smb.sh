#!/bin/bash
BASEDIR=/data/library/music
for m in `cat /etc/smbmounts.conf | grep -v ^#`; do
  dir=`echo $m | awk -F, '{print $1}'`
  if [ ! -d $BASEDIR/$dir ]; then
    mkdir -p $BASEDIR/$dir
  fi
  # Check if share is on a .local host, resolve this first
  HOST=`echo $m | awk -F, '{print $2}' | awk -F\/ '{print $3}'`
  if [[ $HOST == *.local ]]; then 
    IP=`avahi-resolve-host-name $HOST | awk '{print $2}'`
    if [ "$IP" != "" ]; then
      m=`echo $m | sed s/$HOST/$IP/`
    fi
  fi  
  mountcmd=`echo $m | awk -F, '{print "mount -t cifs -o user=" $3 ",password=" $4 " " $2 " /data/library/music/" $1}'`
  ${mountcmd}
done
if [ -x /opt/hifiberry/bin/update-mpd-db ]; then
 /opt/hifiberry/bin/update-mpd-db &
fi
