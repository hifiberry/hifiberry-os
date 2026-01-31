#!/bin/bash
cd `dirname $0`
BASE=riaa
DEB_PACKAGE=ladspa-riaa
rm -rf $BASE
rm -f $DEB_PACKAGE*.build $DEB_PACKAGE*.changes $DEB_PACKAGE*.dsc $DEB_PACKAGE*.deb $DEB_PACKAGE*.buildinfo $DEB_PACKAGE*.tar.gz
rm -f $DEB_PACKAGE-dbgsym*.deb
echo "Cleaned up $DEB_PACKAGE build artifacts."
