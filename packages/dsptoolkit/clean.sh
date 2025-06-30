#!/bin/bash
cd `dirname $0`
BASE=hifiberry-dsp
rm -rf $BASE
rm -f $BASE*.build $BASE*.changes  $BASE*.dsc $BASE*.buildinfo $BASE*.tar.gz
rm -f python*-$BASE*.deb 
