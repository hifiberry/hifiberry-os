#!/bin/bash
cat ../buildroot/package/gstreamer1/gstreamer1/gstreamer1.mk | grep -v BR2_PACKAGE_VALGRIND > ../buildroot/package/gstreamer1/gstreamer1/gstreamer1.mk.new
mv ../buildroot/package/gstreamer1/gstreamer1/gstreamer1.mk ../buildroot/package/gstreamer1/gstreamer1/gstreamer1.mk.orig
mv ../buildroot/package/gstreamer1/gstreamer1/gstreamer1.mk.new ../buildroot/package/gstreamer1/gstreamer1/gstreamer1.mk
