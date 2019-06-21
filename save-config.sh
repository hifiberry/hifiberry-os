#!/bin/bash
cd `dirname $0`/../buildroot
NAME=$1
if [ "$NAME" == "" ]; then
 	NAME=hifiberryos_defconfig
fi
make BR2_EXTERNAL=../hifiberry-os/buildroot savedefconfig BR2_DEFCONFIG=../hifiberry-os/buildroot/configs/$NAME
