#!/bin/bash
for P in channelSelect invert IIR_ levels delay; do
	sed -i s/${P}C/${P}F/g $1
	sed -i s/${P}A/${P}C/g $1
	sed -i s/${P}F/${P}A/g $1
	sed -i s/${P}D/${P}G/g $1
	sed -i s/${P}B/${P}D/g $1
	sed -i s/${P}G/${P}B/g $1
done

sed -i 's/Beocreate Universal/DAC+ DSP Universal/g' $1
sed -i 's/beocreate-universal/dacdsp-universal/g' $1
sed -i 's/beocreate-4ca-mk1/hifiberry-dacdsp/g' $1
sed -i 's/Beocreate 4-Channel Amplifier/DAC+ DSP/g' $1

# Remove daisy chaining feature
sed -i '/DaisyChain/d' $1
