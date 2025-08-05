#!/bin/bash

# Configure the hardware
sudo modprobe i2c-dev
./configure-hardware

# Install DSP profile
banner "Prog. DSP"
dsptoolkit install-profile ./dsp1.xml
banner "Done"


OVERALL_STATUS=0

# --- Test 1: Analog ---
banner "Testing"

echo "Running analog test..."
python ./routing.py --matrix in_analog --execute

play -n synth 3 sine 1000 &
PLAY_PID=$!

./check-rms 2 1 0.5 1
RMS_ANALOG=$?

wait "$PLAY_PID"

if [ "$RMS_ANALOG" -ne 0 ]; then
    OVERALL_STATUS=1
fi

# --- Test 2: AES ---
echo "Running AES test..."
python ./routing.py --matrix in_aes --execute

play -n synth 3 sine 1000 &
PLAY_PID=$!

./check-rms 2 1 0.5 1
RMS_AES=$?

wait "$PLAY_PID"

if [ "$RMS_AES" -ne 0 ]; then
    OVERALL_STATUS=1
fi

# --- Show banners ---
echo
if [ "$RMS_ANALOG" -eq 0 ]; then
    banner "Analog OK"
else
    banner "Fail analog"
fi

if [ "$RMS_AES" -eq 0 ]; then
    banner "AES OK"
else
    banner "Fail AES"
fi

# Exit status
exit "$OVERALL_STATUS"

