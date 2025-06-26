#!/usr/bin/make -f

# Simple Makefile for hifiberry-eeprom package

all:
	@echo "Nothing to build - this is a data package"

install:
	mkdir -p $(DESTDIR)/usr/share/hifiberry-eeprom
	cp -r eeprom/*.eep eeprom/*.txt eeprom/*.sh $(DESTDIR)/usr/share/hifiberry-eeprom/
	chmod 755 $(DESTDIR)/usr/share/hifiberry-eeprom/*.sh

clean:
	@echo "Nothing to clean"

.PHONY: all install clean
