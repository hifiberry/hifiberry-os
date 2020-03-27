#!/bin/bash
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

 GPIO=`grep controller:ac2.plugins.control.rotary.Rotary /newroot/etc/audiocontrol2.conf`
 if [ "$GPIO" == "" ]; then
   cat <<EOF >> /newroot/etc/audiocontrol2.conf

[controller:ac2.plugins.control.rotary.Rotary]
clk = 23
dt = 24
sw = 25
step = 5
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
 if [ -f /newroot/etc/systemd/network/dhcp.network ]; then
  echo "Renaming dhcp.network to eth0.network"
  mv /newroot/etc/systemd/network/eth0.network /newroot/etc/systemd/network/eth0.network.bak
  mv /newroot/etc/systemd/network/dhcp.network /newroot/etc/systemd/network/eth0.network
 fi
fi
