#!/bin/bash
cd `dirname $0`
BASE=acr
rm -rf $BASE
rm $BASE*.build $BASE*.changes  $BASE*.dsc $BASE*.deb $BASE*.buildinfo $BASE*.tar.gz
echo "Cleaned up $BASE build artifacts."
