#!/bin/bash
cd `dirname $0`
BASE=hifiberry-shairport
rm -rf hifiberry-shairport
rm -f $BASE*.build $BASE*.changes $BASE*.dsc $BASE*.deb $BASE*.buildinfo $BASE*.tar.gz
echo "Cleaned up $BASE build artifacts."
