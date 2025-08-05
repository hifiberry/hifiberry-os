#!/bin/bash

MYDIR=`dirname $0`
PATH=$PATH:$MYDIR
cd /tmp

# Configure the hardware
sudo modprobe i2c-dev
$MYDIR/configure-hardware

# Install DSP profile
figlet "Programming DSP"
dsptoolkit install-profile $MYDIR/dsp1.xml
figlet "Done"


OVERALL_STATUS=0

# --- Test 1: Analog ---
figlet "Testing"

echo "Running analog test..."
python $MYDIR/routing.py --matrix in_analog --execute

play -n synth 3 sine 1000 &
PLAY_PID=$!

$MYDIR/check-rms 2 1 0.5 1
RMS_ANALOG=$?

wait "$PLAY_PID"

if [ "$RMS_ANALOG" -ne 0 ]; then
    OVERALL_STATUS=1
fi

# --- Test 2: AES ---
echo "Running AES test..."
python $MYDIR/routing.py --matrix in_aes --execute

play -n synth 3 sine 1000 &
PLAY_PID=$!

$MYDIR/check-rms 2 1 0.5 1
RMS_AES=$?

wait "$PLAY_PID"

if [ "$RMS_AES" -ne 0 ]; then
    OVERALL_STATUS=1
fi

# --- Show banners ---
echo
if [ "$RMS_ANALOG" -eq 0 ]; then
    figlet "Analog OK"
else
    figlet "Fail analog"
fi

if [ "$RMS_AES" -eq 0 ]; then
    figlet "AES OK"
else
    figlet "Fail AES"
fi

# Exit status
exit "$OVERALL_STATUS"

