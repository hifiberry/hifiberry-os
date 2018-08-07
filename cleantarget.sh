#!/bin/bash
cd `dirname $0`/../buildroot
rm -rf output/target
find output/ -name ".stamp_target_installed" |xargs rm -rf 
