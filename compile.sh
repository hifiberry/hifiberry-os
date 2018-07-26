#!/bin/bash
cd `dirname $0`/../buildroot
if [ "$1" != "" ]; then
 rm -rf output/build/$1*
fi
make
