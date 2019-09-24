#!/bin/bash

if [ "$1" == "" ]; then
 VERSION=3
 echo No version given, assuming Pi$VERSION
else
 VERSION=$1
fi 

current_version=`cat .piversion`
if [ "$VERSION" == "$current_version" ]; then
 echo "Already configured for Pi${VERSION}, doing nothing"
 exit 0
fi

echo $VERSION > .piversion
echo $VERSION > buildroot/PIVERSION

SRC=configs/hifiberryos
TMP=./tmpfile.$$
DST=./config
PLATFORM=configs/config$VERSION

if [ ! -f $PLATFORM ]; then
 echo Platform default configuration $PLATFORM not found. You need to create one using make xxxx_defconfig in buildroot
 exit 1
fi

cp $SRC $TMP

for i in BR2_ARCH_NEEDS_GCC_AT_LEAST_4_8 BR2_ARCH_NEEDS_GCC_AT_LEAST_4_9 BR2_ARCH_NEEDS_GCC_AT_LEAST_5 BR2_GCC_TARGET_CPU BR2_GCC_TARGET_FPU BR2_cortex_a53 BR2_cortex_a72 BR2_DEFCONFIG BR2_ROOTFS_POST_BUILD_SCRIPT BR2_ROOTFS_POST_IMAGE_SCRIPT BR2_LINUX_KERNEL_DEFCONFIG BR2_LINUX_KERNEL_INTREE_DTS_NAME BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI4 BR2_ARM_CPU_HAS_NEON BR2_ARM_CPU_HAS_VFPV3 BR2_ARM_CPU_HAS_VFPV4 BR2_ARM_CPU_HAS_FP_ARMV8 BR2_ARM_CPU_HAS_THUMB BR2_ARM_CPU_ARMV6 BR2_arm1176jzf_s BR2_ARM_FPU_VFPV2 BR2_ARM_FPU_VFPV3 BR2_ARM_FPU_VFPV3D16 BR2_ARM_FPU_VFPV4 BR2_ARM_FPU_VFPV4D16 BR2_ARM_FPU_NEON BR2_ARM_FPU_FP_ARMV8 BR2_ARM_FPU_NEON_FP_ARMV8 BR2_SYSTEM_DHCP BR2_PACKAGE_BAYER2RGB_NEON BR2_PACKAGE_JPEG_SIMD_SUPPORT BR2_PACKAGE_NE10 BR2_PACKAGE_OPENBLAS BR2_PACKAGE_OPENBLAS_DEFAULT_TARGET BR2_PACKAGE_OPENBLAS_ARCH_SUPPORTS BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI4 BR2_ARM_INSTRUCTIONS_THUMB2 BR2_ARM_ENABLE_VFP BR2_ARM_CPU_ARMV7A BR2_cortex_a7; do
  cat $TMP | grep  -v $i > $DST
  cat $PLATFORM | grep $i >> $DST
  mv $DST $TMP
done

if [ "$2" == "release" ]; then
 # for the releases, remove debug tools
 for i in BR2_PACKAGE_STRESS BR2_PACKAGE_STRESS_NG BR2_PACKAGE_STRACE; do
   echo "$i=n" >> $TMP
 done
fi

# Roon is not supported on the Pi Zero
if [ "$1" == "0w" ]; then
 echo "BR2_PACKAGE_RAAT=n" >> $TMP
fi

mv $TMP $DST
mv $DST ../buildroot/.config
./clean.sh
