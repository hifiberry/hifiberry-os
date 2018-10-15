#!/bin/bash
cd `dirname $0`/../buildroot
rm -rf ~/buildroot/dl
if [ "$1" != "" ]; then
 rm -rf output/build/$1*
fi
make
