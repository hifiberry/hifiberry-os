#!/bin/bash

touch /newroot/etc/quiet_start

V=`cat /etc/hifiberry.version`
if [ "$V" == "" ]; then
 V=0
fi
echo "Upgrading from version $V"
if [ "$V" -lt 20191022 ]; then
 echo "Version < 20191022, overwriting some configurations"
 echo 
 echo "Installing default configs for Audiocontrol and Beocreate"
 echo "audiocontrol2.conf"
 cp /newroot/etc/audiocontrol2.conf /newroot/etc/audiocontrol2.conf.bak
 cp /newroot/etc/audiocontrol2.conf.orig /newroot/etc/audiocontrol2.conf
 echo "beocreate/system.json"
 cp /newroot/etc/beocreate/system.json /newroot/etc/beocreate/system.json.bak
 cp /newroot/etc/beocreate/system.json.orig /newroot/etc/beocreate/system.json
 echo "beocreate/sources.json"
 cp /newroot/etc/beocreate/sources.json /newroot/etc/beocreate/sources.json.bak
 cp /newroot/etc/beocreate/sources.json.orig /newroot/etc/beocreate/sources.json
 echo "Needs sound card reconfiguration"
 rm /newroot/etc/hifiberry.state
fi

if [ "$V" -lt 20200201 ]; then
 echo "Version < 20200101, adding privacy section to audiocontrol"
 echo
 FOUND=`cat /newroot/etc/audiocontrol2.conf | grep '\[privacy\]'`
 if [ "$FOUND" == "" ]; then
  echo >> /newroot/etc/audiocontrol2.conf
  echo '[privacy]' >> /newroot/etc/audiocontrol2.conf
  echo 'external_metadata=1' >> /newroot/etc/audiocontrol2.conf
  echo "audiocontrol2.conf done"
 else
  echo "General section already exists"
 fi

 echo "Adding exclusive audio mode configuration to shairport"
 FOUND=`cat /newroot/etc/shairport-sync.conf | grep pause-all`
 if [ "$FOUND" == "" ]; then
  cp /newroot/etc/shairport-sync.conf /newroot/etc/shairport-sync.conf.orig
  sed -i '/sessioncontrol\ =/,$d' /newroot/etc/shairport-sync.conf
  cat <<EOF >> /newroot/etc/shairport-sync.conf
sessioncontrol =
{
  run_this_before_play_begins = "/opt/hifiberry/bin/pause-all shairport";
  wait_for_completion = "yes";
  allow_session_interruption = "yes";
  session_timeout = 20;
};
EOF
  echo "shairport-sync.conf done"
 else
  echo "configuration already exists"
 fi

 echo "Removing CURRENT_EXCLUSIVE"
 cat /newroot/etc/hifiberry.state | grep -v "CURRENT_EXCLUSIVE" > /tmp/x
 mv /tmp/x /newroot/etc/hifiberry.state

 echo "Enabling exclusive audio mode"
 touch /newroot/etc/force_exclusive_audio

fi

if [ "$V" -lt 20200301 ]; then
 echo "Version < 20200301, adapting audiocontrol.conf"
 # New way to include plugins
 sed -i 's/\[keyboard\]/[controller:ac2.plugins.control.keyboard.Keyboard]/' /newroot/etc/audiocontrol2.conf

 LAMETRIC=`grep LaMetricPush /newroot/etc/audiocontrol2.conf`
 if [ "$LAMETRIC" == "" ]; then
cat <<EOF >> /newroot/etc/audiocontrol2.conf

[metadata:ac2.plugins.metadata.lametric.LaMetricPush]
EOF
 fi

fi

if [ "$V" -lt 20200401 ]; then
 echo "Version < 20200301, adapting audiocontrol.conf"

 # Remove postgres plugin
 cat /newroot/etc/audiocontrol2.conf | grep -iv postgres > /tmp/audiocontrol2.conf
 cp /newroot/etc/audiocontrol2.conf /newroot/etc/audiocontrol2.conf.bak
 cp /tmp/audiocontrol2.conf  /newroot/etc/audiocontrol2.conf

 # Overwrite asound.conf
 TTABLE=`cat /newroot/etc/asound.conf | grep ttable_config`
 if [ "$TTABLE" == "" ]; then 
  echo "Adding ttable configuration to asound.conf"
  cp /newroot/etc/asound.conf /newroot/etc/asound.conf.bak
  cp /newroot/etc/asound.conf.exclusive /newroot/etc/asound.conf
 fi 

 # Overwrite mpd.conf
 MPDCONFOK=`cat /newroot/etc/mpd.conf | grep device | grep default`
 if [ "MPDCONFOK" == "" ]; then
  echo "Using default mpd.conf"
  cp /newroot/etc/mpd.conf /newroot/etc/mpd.conf.bak
  cp /newroot/etc/mpd.conf.default /newroot/etc/mpd.conf
 fi

 # If Mopidy is new, remove /etc/hifiberry.state
 if [ ! -f /etc/mopidy.conf ]; then
  echo "Reconfiguring system after reboot"
  rm /newroot/etc/hifiberry.state
 fi

 # dhcp has been renamed to wireless
# if [ -f /newroot/etc/systemd/network/dhcp.network ]; then
#  echo "Renaming dhcp.network to eth0.network"
#  mv /newroot/etc/systemd/network/eth0.network /newroot/etc/systemd/network/eth0.network.bak
#  mv /newroot/etc/systemd/network/dhcp.network /newroot/etc/systemd/network/eth0.network
# fi

 # Revert back change introduced with latest buildroot
 if [ -f /newroot/etc/systemd/network/eth0.network ]; then
  echo "Renaming eth0.network to dhcp.network"
  mv /newroot/etc/systemd/network/dhcp.network /newroot/etc/systemd/network/dhcp.network.bak
  mv /newroot/etc/systemd/network/eth0.network /newroot/etc/systemd/network/dhcp.network
 fi

 # force_eeprom_read workaround
# mount -o rw,remount /boot
# echo "force_eeprom_read=0" >> /boot/config.txt
fi

if [ "$V" -lt 20200408 ]; then
 echo "Version < 20200408, cleaning usage data"
 rm /newroot/var/lib/hifiberry/usage.json
fi 

if [ "$V" -lt 20200416 ]; then
 echo "Version < 20200416, switching to new asound.conf with eq support"
 cp /newroot/etc/asound.conf /newroot/etc/asound.conf.bak
 cp /newroot/etc/asound.conf.eq /newroot/etc/asound.conf
fi

if [ "$V" -lt 20200420 ]; then
 echo "Version < 20200420, extracting firmware again (due to bug in updater)"
 if [ -f /newroot/usr/lib/firmware/rpi/zImage ]; then
  echo "Using zImage from new RPI firmware"
  cp -rv /newroot/usr/lib/firmware/rpi/* /boot
 fi
fi

if [ "$V" -lt 20200530 ]; then
 echo "Version < 20200530, disabling alsaeq"
 cp /newroot/etc/asound.conf.eq /newroot/etc/asound.conf
 FKMS=`cat /boot/config.txt | grep vc4-fkms-v3d`
 if [ "$FKMS" == "" ]; then 
  echo "Adding video driver"
  mount -o remount,rw /boot
  echo "dtoverlay=vc4-fkms-v3d,audio=off" >> /boot/config.txt
 fi
fi

if [ "$V" -lt 20200630 ]; then
 echo "Version < 20200630"
 echo "changing mpd logging to systemd"
 cp /newroot/etc/mpd.conf /newroot/etc/mpd.conf.bak
 sed -i 's/^log_file.*/log_file "syslog"/' /newroot/etc/mpd.conf
 
 SOCK=`cat /newroot/etc/mpd.conf | grep bind_to_address | grep /var/run/mpd/socket`
 if [ "$SOCK" == "" ]; then
   echo "Adding socket configuration to mpd"
   echo 'bind_to_address "/var/run/mpd/socket"' >> /newroot/etc/mpd.conf
 fi

 ACMPD=`cat /newroot/etc/audiocontrol2.conf | grep "\[mpd\]"`
 if [ "$ACMPD" == "" ]; then
   echo "adding mpd configuration to audiocontrol"
   cp /newroot/etc/audiocontrol2.conf /newroot/etc/audiocontrol2.conf.bak
   echo "" >> /newroot/etc/audiocontrol2.conf
   echo "[mpd]" >> /newroot/etc/audiocontrol2.conf 
   echo "musicdir=/data/library/music" >> /newroot/etc/audiocontrol2.conf
 fi
fi

sync

if [ "$V" -lt 20200706 ]; then
 echo "Version < 20200706"
 
 AUTOUPDATE=`cat /newroot/etc/mpd.conf | grep auto_update`
 if [ "$AUTOUPDATE" == "" ]; then
   echo "Adding automatic update to mpd"
   echo 'auto_update "yes"' >> /newroot/etc/mpd.conf
 else
   echo $AUTOUPDATE
 fi

 STICKERS==`cat /newroot/etc/mpd.conf | grep sticker_file`
 if [ "$STICKERS" == "" ]; then
   echo "Adding mpd sticker database"
   echo 'sticker_file "/library/mpd-sticker.db"' >> /newroot/etc/mpd.conf
 else
   echo $STICKERS
 fi

 sed -i 's/,/\;/g' /newroot/etc/smbmounts.conf
fi 

if [ "$V" -lt 20200930 ]; then
 echo "Version < 20200930"
fi

if [ "$V" -l 20201030 ]; then
 echo "Version < 20201030"

 cat /newroot/etc/audiocontrol2.conf | grep -v "spotifyd=spotify" | grep -v "mpd=mpd-mpris" > /tmp/audiocontrol2.conf
 diff /tmp/audiocontrol2.conf /newroot/etc/audiocontrol2.conf >/dev/null
 if [ "$?" != "0" ]; then
   echo "Removing MPD and spotify MPRIS watchdogs"
   mv /newroot/etc/audiocontrol2.conf /newroot/etc/audiocontrol2.conf.bak
   mv /tmp/audiocontrol2.conf /newroot/etc/audiocontrol2.conf
 fi

 echo "Making sure, players will be configured correctly"
 rm  /newroot/etc/hifiberry.state
fi


echo "Upgrading configuration files done"
