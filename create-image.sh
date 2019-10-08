#!/bin/bash
cd `dirname $0`

PLATFORM=`cat .piversion`
if [ "$PLATFORM" == "" ]; then
 echo "Pi platform undefined. You have to create the config files using build-config.sh before compiling the system."
 echo "Aborting..."
 exit 1
fi

if [ "$1" != "" ]; then
  echo "Using timestamp $1"
  TS=$1
else
  TS=`date +%Y%m%d`
fi

cd `dirname $0`
MYDIR=`pwd`
echo $MYDIR
cp ../buildroot/output/images/sdcard.img images/hifiberryos-$TS-pi$PLATFORM.img
pushd images
if [ -f hifiberryos-pi$PLATFORM.zip ]; then
 rm hifiberryos-pi$PLATFORM.zip
fi
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
