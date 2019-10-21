#!/bin/bash
V=`cat /etc/hifiberry.version`
if [ "$V" -lt 20191022 ]; then
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

