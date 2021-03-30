#!/bin/bash
BASEDIR=/data/library/music
SMB_MOUNT=/etc/smbmounts.conf
SMB_PATCH=/tmp/smbmounts_patch

echo "Patching ${SMB_MOUNT}"
# Fix for Beocreate: not using proper EOF and handling shares with spaces beeing incorrectly translated to MOUNTID
if test -f "${SMB_PATCH}"; then
  rm ${SMB_PATCH}
fi
touch ${SMB_PATCH}

readarray lines < /etc/smbmounts.conf
for i in "${lines[@]}"
do
  line=`echo $i | xargs`

  if [ "$line" != ""  ]; then
    readarray -d \; -t parts <<< "$line"
    MOUNTID=`echo "${parts[0]}" | sed -e 's/ //g'` # strip spaces from MOUNTID
    SHARE="${parts[1]}"
    USER="${parts[2]}"
    PASSWORD="${parts[3]//$'\n'}" # fixes newline inserts by Beocreate
    MOUNTOPTS="${parts[4]//$'\n'}" #

    if [ "$MOUNTOPTS" == "" ]; then
      MOUNTOPTS="rw"
    fi

    # Create mount folder
    if [ ! -d "$BASEDIR/$MOUNTID" ]; then
      echo "CREATE FOLDER"
      mkdir -p "$BASEDIR/$MOUNTID"
    fi

    echo "mountid=${MOUNTID}, share=${SHARE}, user=${USER}, passwd=${PASSWORD}, mountopts=${MOUNTOPTS}"
    # mount folder
    mount.cifs "${SHARE}" "$BASEDIR/$MOUNTID" -o user="${USER}",password="${PASSWORD}","${MOUNTOPTS}"

    if [ -x /opt/hifiberry/bin/report-activation ]; then
      /opt/hifiberry/bin/report-activation mount_samba
    fi

    # add fixes to patch file
    printf "$MOUNTID;$SHARE;$USER;$PASSWORD\n" >> ${SMB_PATCH}
  fi
done

# apply patched file to /etc/smbmounts.conf, this also fixes ui when UNC path contains space
mv ${SMB_PATCH} ${SMB_MOUNT}

if [ "$1" != "--no-update" ]; then
  if [ -x /opt/hifiberry/bin/update-mpd-db ]; then
    /opt/hifiberry/bin/update-mpd-db
  fi
fi

