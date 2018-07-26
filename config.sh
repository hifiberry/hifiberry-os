#!/bin/bash
cd `dirname $0`/../buildroot
make BR2_EXTERNAL=../hifiberry-os/buildroot menuconfig
