#!/bin/bash
cd `dirname $0`
BASE=hifiberry-configurator
rm -rf configurator
rm -f $BASE*.build $BASE*.changes $BASE*.dsc $BASE*.deb $BASE*.buildinfo $BASE*.tar.gz
rm -f python*-$BASE*.deb
rm -rf deb_dist
echo "Cleaned up $BASE build artifacts."
