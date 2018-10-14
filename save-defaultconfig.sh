#!/bin/bash
cd `dirname $0`/../buildroot
make BR2_EXTERNAL=../hifiberry-os/buildroot savedefconfig BR2_DEFCONFIG=../hifiberry-os/buildroot/configs/hifiberryos_defconfig
