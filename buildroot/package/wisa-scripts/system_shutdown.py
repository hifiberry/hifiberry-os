#!/usr/bin/python
# filename = system_shutdown.py

from pysummit.bsp.pi_bsp import PiBSP
from pysummit.devices import TxAPI
from pysummit.devices import RxAPI
from pysummit import descriptors
import argparse

def main():
        bsp = PiBSP()
        TX = TxAPI(bsp=bsp)

        print 'Resetting all Rx devices, forgetting configuration and Shutting down network'
        TX.reset(0xFF)  #0xFF = "reset all RX devices"

        TX.save_configuration(1)
        TX.shutdown()

        print 'Rebooting Tx module'
        TX.reboot()

        print 'Ready for next setup'

if __name__ == '__main__':
        main()
