#!/bin/bash
cd `dirname $0`
BASE=speakereq
rm -rf $BASE
rm -f $BASE*.build $BASE*.changes $BASE*.dsc $BASE*.deb $BASE*.buildinfo $BASE*.tar.gz
rm -f $BASE-dbgsym*.deb
echo "Cleaned up $BASE build artifacts."
