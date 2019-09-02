#!/bin/bash
cd `dirname $0`
TS=`date +%Y%m%d`
for i in 0w 3 4; do
  clear
  echo Buildung for Raspberry Pi $i
  echo ============================
  echo
  ./clean.sh
  ./build-config.sh $i
  ./compile.sh
  mv ../buildroot/output/images/sdcard.img images/hifiberryos-$TS-pi$i.img
  pushd images
  zip hifiberryos-pi$i.zip hifiberryos-$TS-pi$i.img
  popd
  sleep 600
done

