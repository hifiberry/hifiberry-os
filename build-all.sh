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
  ./create-image $i
done

