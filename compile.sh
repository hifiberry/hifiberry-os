#!/bin/bash
cd `dirname $0`
MYDIR=`pwd`
TS=`date +%Y%m%d`
echo $TS > buildroot/VERSION
cd $MYDIR/../buildroot
rm -rf ~/buildroot/dl
if [ "$1" != "" ]; then
 rm -rf output/build/$1*
fi
make
