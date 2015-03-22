#!/bin/sh
PATH=/usr/bin
while [ "$x" == "" ]; do
 l=`aplay -l | grep card | wc -l`
 if [ "$l" != "0" ]; then
   echo Found $l sound cards
   x="done"
 else
  sleep 1
 fi
done
