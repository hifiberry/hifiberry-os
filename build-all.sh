#!/bin/bash
cd `dirname $0`
TS=`date +%Y%m%d`
echo "VERSION=$TS" > images/listing
for i in 0w 2 4 3; do
#for i in 3; do 
  clear
  echo Buildung for Raspberry Pi $i
  echo ============================
  echo
  ./build-config.sh $i
  ./compile.sh
  ./create-image.sh $i $TS
  echo $TS > images/VERSION
  echo "UPDATER${i}=updater-$TS-pi${i}.tar.gz" >> images/listing
done
