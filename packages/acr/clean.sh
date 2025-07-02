#!/bin/bash
cd `dirname $0`
BASE=hifiberry-audiocontrol
rm -rf acr hifiberry-audiocontrol-*
rm -f $BASE*.build $BASE*.changes  $BASE*.dsc $BASE*.deb $BASE*.buildinfo $BASE*.tar.gz
echo "Cleaned up $BASE build artifacts."
