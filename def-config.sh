#!/bin/bash
cd `dirname $0`/../buildroot
make defconfig BR2_DEFCONFIG=../hifiberry-os/buildroot/configs/raspberypi3_defconfig


