#!/bin/bash
for m in `cat /etc/smbmounts.conf | grep -v ^#`; do
 dir=`echo $m | awk -F, '{print $1}'`
 mkdir -p $dir
 mountcmd=`echo $m | awk -F, '{print "mount -t cifs -o user=" $3 ",password=" $4 " " $2 " /data/library/music/" $1}'`
 ${mountcmd}
done

