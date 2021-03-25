#!/bin/bash
BASEDIR=/data/library/music
while read -r line; do
  readarray -d \; -t parts <<< "$line"
  MOUNTID=${parts[0]}
  SHARE=${parts[1]}
  USER=${parts[2]}
  PASSWORD=${parts[3]}
  MOUNTOPTS=${parts[4]}

  # Remove newline from last parameter
  PASSWORD=$(echo $PASSWORD|tr -d '\n')
  MOUNTOPTS=$(echo $MOUNTOPTS|tr -d '\n')

  echo "DEBUG"
  echo $USER
  echo "mountid=${MOUNTID}, share=${SHARE}, user=${USER}, passwd=${PASSWORD}, mountopts=${MOUNTOPTS}"

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

  mountcmd="mount -t cifs -o user=$USER,password=$PASSWORD,$MOUNTOPTS $SHARE /data/library/music/$MOUNTID"
  echo ${mountcmd}
  ${mountcmd}

  if [ -x /opt/hifiberry/bin/report-activation ]; then
    /opt/hifiberry/bin/report-activation mount_samba
  fi
done < /etc/smbmounts.conf

if [ "$1" != "--no-update" ]; then
  if [ -x /opt/hifiberry/bin/update-mpd-db ]; then
    /opt/hifiberry/bin/update-mpd-db &
  fi
fi

