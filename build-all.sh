#!/bin/bash
cd `dirname $0`
TS=`date +%Y%m%d`
for i in 0 3 4; do
  ./clean.sh
  ./build-config.sh $i
  ./compile.sh
  mv ../buildroot/output/images/sdcard.img images/hifiberryos-$TS.img
  cd images
  zip hifiberryos-$TS.zip hifiberryos-$TS.img
done

