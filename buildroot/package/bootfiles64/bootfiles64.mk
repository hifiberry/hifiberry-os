################################################################################
#
# bootfiles64
#
################################################################################

BOOTFILES64_VERSION = 7e6decce72fdff51923e9203db46716835ae889a
BOOTFILES64_SITE = $(call github,raspberrypi,firmware,$(BOOTFILES64_VERSION))
BOOTFILES64_DEPENDENCIES = rpi-firmware

BOOTFILES64_DTB_FILES = \
   bcm2710-rpi-3-b-plus.dtb \
   bcm2710-rpi-3-b.dtb \
   bcm2710-rpi-cm3.dtb \
   bcm2710-rpi-zero-2-w.dtb \
   bcm2710-rpi-zero-2.dtb \
   bcm2711-rpi-4-b.dtb \
   bcm2711-rpi-cm4-io.dtb \
   bcm2711-rpi-cm4.dtb \
   bcm2711-rpi-cm4s.dtb \
   bcm2712-rpi-5-b.dtb 
BOOTFILES64_FW_FILES = \
   bootcode.bin \
   fixup.dat \
   fixup4.dat \
   fixup4x.dat \
   fixup_x.dat \
   start.elf \
   start4.elf \
   start4x.elf \
   start_x.elf

define BOOTFILES64_INSTALL_TARGET_CMDS
 for file in $(BOOTFILES64_DTB_FILES); do \
	echo $(BINARIES_DIR)/$$file; \
        $(INSTALL) -D -m 0644 $(@D)/boot/$$file $(BINARIES_DIR)/$$file; \
 done
 for file in $(BOOTFILES64_FW_FILES); do \
        echo $(BINARIES_DIR)/$$file; \
        $(INSTALL) -D -m 0644 $(@D)/boot/$$file $(BINARIES_DIR)/rpi-firmware/$$file; \
 done
endef

$(eval $(generic-package))

