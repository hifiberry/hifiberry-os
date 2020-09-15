#!/bin/bash
# Make sure not to use DNSSEC for NTP servers as we don't know the
# correct time before contacting the NTP servers
for i in `ls /sys/class/net | grep -v lo`; do 
  resolvectl nta $i ntp.org
done
