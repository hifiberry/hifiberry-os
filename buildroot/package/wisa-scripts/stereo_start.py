#!/usr/bin/python

from pysummit.bsp.pi_bsp import PiBSP
from pysummit.devices import TxAPI
from pysummit.devices import RxAPI
from pysummit import descriptors
import argparse

def config_i2s_clocks():
        clks = descriptors.AUDIO_CLOCK_SETUP()
        clks.audioSource = 1    # I2S
        clks.audioSetup.driveClks = 0   # i2s_clocks driven externally
        return clks

def main():
        bsp = PiBSP()
        TX = TxAPI(bsp=bsp)

        print("Discover")
        TX.disco(beacon_time=5500, restore=False)

        print("Configure I2S clocks")
        TX.set_i2s_clocks(config_i2s_clocks())

        print("Configure RX0 to audio slot 1")
        TX.slot(0,1)

        print("Configure RX1 to audio slot 2")
        TX.slot(1,2)

        print("Start network")
        TX.start()

        print("Set volume to max")
        TX.volume(0, 0xfffff)

if __name__ == '__main__':
        main()
