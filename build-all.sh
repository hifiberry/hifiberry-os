#!/bin/bash
cd `dirname $0`
TS=`date +%Y%m%d`
for i in 0w 2 3 4; do
  clear
  echo Buildung for Raspberry Pi $i
  echo ============================
  echo
  ./build-config.sh $i
  ./compile.sh
  ./create-image.sh $i
done

