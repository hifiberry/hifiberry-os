#!/bin/bash
dsptoolkit install-profile https://raw.githubusercontent.com/hifiberry/hifiberry-dsp/master/sample_files/xml/dacdsp-default.xml
cat <<EOF >limit.txt
volumeLimitRegister: -30db
EOF
dsptoolkit apply-settings ./limit.txt
dsptoolkit store-settings ./limit.txt

