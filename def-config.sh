#!/bin/bash
cd `dirname $0`/../buildroot
if [ "$1" == "" ]; then
	F=buildroot/configs/hifiberryos_config
else
	F=$1
fi
F=`readlink -f $F`
if [ -f $F ]; then
	make defconfig BR2_DEFCONFIG=$F
else
	echo "Config file $F does not exist"
fi


