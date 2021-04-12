#!/usr/bin/python3

from pysummit.bsp.pi_bsp import PiBSP
from pysummit.devices import TxAPI
from pysummit import descriptors
from pysummit import testprofile
import os
import argparse

def config_i2s_clocks():
        clks = descriptors.AUDIO_CLOCK_SETUP()
        clks.audioSource = 1    # I2S
        clks.audioSetup.driveClks = 0   # i2s_clocks driven externally
        return clks

def wisa_push_map(tx_dev, filename):
        tp = testprofile.TestProfile()
        if(os.path.exists(filename)):
            tp.readfp(open(filename))
        else:
            __logger.error("No such file: %s" % filename)
        print("validating %s" % (filename))
        if(tp.validate()):
            num_speakers = len(tp)
            print("number of speakers %i" % num_speakers)
            tx_dev.push_map_profile(tp, num_speakers)
        print("done.")

def main():
        bsp = PiBSP()
        TX = TxAPI(bsp=bsp)

        print("Discover")
        TX.disco(beacon_time=5500, restore=False)

        print("Configure I2S clocks")
        TX.set_i2s_clocks(config_i2s_clocks())

        print("Start network")
        TX.start()

        print("push_map ....")
        wisa_push_map(TX, "/opt/wisa/etc/room.cfg")

        print("Set volume to max")
        TX.volume(0, 0xfffff)

if __name__ == '__main__':
        main()
