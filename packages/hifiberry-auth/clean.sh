#!/bin/bash
cd `dirname $0`
BASE=hifiberry-auth
rm -rf hifiberry-auth
rm -f $BASE*.build $BASE*.changes $BASE*.dsc $BASE*.deb $BASE*.buildinfo $BASE*.tar.gz $BASE*.tar.xz
echo "Cleaned up $BASE build artifacts."
