#!/bin/bash
cd `dirname $0`
TS=`date +%Y%m%d`
echo "VERSION=$TS" > images/listing
for i in 0w 2 4 3; do
  clear
  echo Buildung for Raspberry Pi $i
  echo ============================
  echo
  ./build-config.sh $i
  ./compile.sh
  ./create-image.sh $i
  echo $TS > images/VERSION
  echo "UPDATE${i}=updater-$TS-pi${o}.tar.gz" >> images/listing
done
