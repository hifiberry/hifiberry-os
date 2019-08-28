#!/bin/bash
cd `dirname $0`
MYDIR=`pwd`
cd $MYDIR/../buildroot
rm -rf ~/buildroot/dl
if [ "$1" != "" ]; then
 rm -rf output/build/$1*
fi

if [ "$1" == "1" ]; then
 sed -i "s/BR2_LINUX_KERNEL_DEFCONFIG.*/BR2_LINUX_KERNEL_DEFCONFIG=\"bcmrpi\"/" .config
 make linux-dirclean
 make linux-rebuild
elif [ "$1" == "3" ]; then
 sed -i "s/BR2_LINUX_KERNEL_DEFCONFIG.*/BR2_LINUX_KERNEL_DEFCONFIG=\"bcm2709\"/" .config
 make linux-dirclean
 make linux-rebuild
elif [ "$1" == "4" ]; then
 sed -i "s/BR2_LINUX_KERNEL_DEFCONFIG.*/BR2_LINUX_KERNEL_DEFCONFIG=\"bcm2711\"/" .config
 make linux-dirclean
 make linux-rebuild
fi

make -j 6 BR2_INSTRUMENTATION_SCRIPTS="$MYDIR/log.sh"
