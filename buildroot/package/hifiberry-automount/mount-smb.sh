#!/bin/bash
BASEDIR=/data/library/music
# change for m in `cat /etc/smbmounts.conf | grep -v ^#`; do because cut path if there is a space in the share path
grep -v '^#' /etc/smbmounts.conf  | while read -r m ; do 
  # Split the line first
  readarray -d \; -t parts <<< "$m"
  MOUNTID=${parts[0]}
  SHARE=${parts[1]}
# add a variable to mount share with space 
  SHAREMOUNT="'"$SHARE"'";
  USER=${parts[2]}
  PASSWORD=${parts[3]}
  MOUNTOPTS=${parts[4]}

  # Remove newline from last parameter
  PASSWORD=$(echo $PASSWORD|tr -d '\n')
  MOUNTOPTS=$(echo $MOUNTOPTS|tr -d '\n')
	
  if [ "$MOUNTOPTS" == "" ]; then
    MOUNTOPTS="rw"
  fi

  if [ ! -d $BASEDIR/$MOUNTID ]; then
    mkdir -p $BASEDIR/$MOUNTID
  fi
  # Check if share is on a .local host, resolve this first
  HOST=`echo $m | awk -F\; '{print $2}' | awk -F\/ '{print $3}'`
  if [[ $HOST == *.local ]]; then 
    IP=`avahi-resolve-host-name -4 $HOST | awk '{print $2}'`
  fi

  # The try to resolve using nmblookup
  if [ "$IP" == "" ]; then
    nmblookup $HOST > /tmp/$$
    if [ "$?" == "0" ]; then
      IP=`nmblookup $HOST|awk 'END{print $1}'`
    fi
  fi

  if [ "$IP" != "" ]; then
    SHARE=`echo $SHARE | sed s/$HOST/$IP/`
  fi
# replace SHARE by SHAREMOUNT
  mountcmd="mount -t cifs -o user=$USER,password=$PASSWORD,$MOUNTOPTS $SHAREMOUNT /data/library/music/$MOUNTID"
# change execute commante   
  echo $mountcmd
  eval $mountcmd

  if [ -x /opt/hifiberry/bin/report-activation ]; then
    /opt/hifiberry/bin/report-activation mount_samba
  fi
done
if [ -x /opt/hifiberry/bin/update-mpd-db ]; then
 /opt/hifiberry/bin/update-mpd-db &
fi
# 
