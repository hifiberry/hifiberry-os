#!/bin/bash
PLATFORM=$1
if [ "$PLATFORM" == "" ]; then
 echo Call with $0 platform where platform is 0w, 3 or 4
 exit 1
fi

TS=`date +%Y%m%d`
cd `dirname $0`
MYDIR=`pwd`
echo $MYDIR
cp ../buildroot/output/images/sdcard.img images/hifiberryos-$TS-pi$PLATFORM.img
pushd images
zip hifiberryos-pi$PLATFORM.zip hifiberryos-$TS-pi$PLATFORM.img
popd
TMPDIR=/tmp/$$
mkdir $TMPDIR
cp ../buildroot/output/images/zImage ../buildroot/output/images/rootfs.ext2 $TMPDIR
pushd $TMPDIR
pwd
ls
tar cvfz $MYDIR/images/updater-$TS-pi$PLATFORM.tar.gz zImage rootfs.ext2
popd
rm -rf $TMPDIR
