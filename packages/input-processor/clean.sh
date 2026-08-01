#!/bin/bash
cd `dirname $0`
BASE=input-processor
DEB_PACKAGE=hifiberry-input-processor
rm -rf $BASE
rm -f $DEB_PACKAGE*.build $DEB_PACKAGE*.changes $DEB_PACKAGE*.dsc $DEB_PACKAGE*.deb $DEB_PACKAGE*.buildinfo $DEB_PACKAGE*.tar.gz
rm -f $DEB_PACKAGE-dbgsym*.deb
# Artefacts from before the ladspa-riaa -> hifiberry-input-processor rename;
# build hosts that predate it still have them lying around.
rm -f ladspa-riaa*.deb
rm -rf riaa
echo "Cleaned up $DEB_PACKAGE build artifacts."
