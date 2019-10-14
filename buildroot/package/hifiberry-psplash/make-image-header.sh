#!/bin/sh

set -e

imageh=psplash-poky-img.h
pic=hifiberryos-logo-black.png
name=POKY_IMG
gdk-pixbuf-csource --macros $pic > $imageh.tmp
sed -e "s/MY_PIXBUF/${name}/g" -e "s/guint8/uint8/g" $imageh.tmp > $imageh && rm $imageh.tmp
imageh=psplash-bar-img.h
pic=black.png
name=BAR_IMG
gdk-pixbuf-csource --macros $pic > $imageh.tmp
sed -e "s/MY_PIXBUF/${name}/g" -e "s/guint8/uint8/g" $imageh.tmp > $imageh && rm $imageh.tmp


