#!/bin/bash
BASEDIR=/data/library/music
while read -r line; do
  # Split the line first
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

  if [ ! -d '$BASEDIR/$MOUNTID' ]; then
    mkdir -p '$BASEDIR/$MOUNTID'
  fi

  # Removed local resolving as it leads to SHARE beeing empty if not resolvable
  mountcmd="mount.cifs '$SHARE' '/data/library/music/$MOUNTID' -o user=$USER,password=$PASSWORD,$MOUNTOPTS"
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

