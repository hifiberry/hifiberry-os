#!/bin/bash

if [ "$1" == "" ]; then
 VERSION=3
 echo No version given, assuming Pi$VERSION
else
 VERSION=$1
fi 

SRC=configs/hifiberryos
TMP=./tmpfile.$$
DST=./config
PLATFORM=configs/config$VERSION

if [ ! -f $PLATFORM ]; then
 echo Platform default configuration $PLATFORM not found. You need to create one using make xxxx_defconfig in buildroot
 exit 1
fi

cp $SRC $TMP

for i in BR2_ARCH_NEEDS_GCC_AT_LEAST_4_8 BR2_ARCH_NEEDS_GCC_AT_LEAST_4_9 BR2_ARCH_NEEDS_GCC_AT_LEAST_5 BR2_GCC_TARGET_CPU BR2_cortex_a53 BR2_cortex_a72 BR2_DEFCONFIG BR2_ROOTFS_POST_BUILD_SCRIPT BR2_ROOTFS_POST_IMAGE_SCRIPT BR2_LINUX_KERNEL_DEFCONFIG BR2_LINUX_KERNEL_INTREE_DTS_NAME BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI4; do
  cat $TMP | grep  -v $i > $DST
  cat $PLATFORM | grep $i >> $DST
  mv $DST $TMP
done

mv $TMP $DST
mv $DST ../buildroot/.config
