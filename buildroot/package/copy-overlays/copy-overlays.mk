################################################################################
#
# copy-overlays
#
################################################################################


COPY_OVERLAYS_DEPENDENCIES = rpi-firmware linux

ifdef COPY_OVERLAYS_PI0w
PIOVERLAYS = bcm2708-rpi-zero-w.dtb
endif

ifdef COPY_OVERLAYS_PI2
PIOVERLAYS = bcm2709-rpi-2-b.dtb
endif

ifdef COPY_OVERLAYS_PI3
PIOVERLAYS = bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-3-b.dtb
endif

ifdef COPY_OVERLAYS_PI4
PIOVERLAYS = bcm2711-rpi-4-b.dtb
endif


define COPY_OVERLAYS_INSTALL_TARGET_CMDS
	# Copy overlays
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/rpi/overlays
        for i in hifiberry vc4 i2c-gpio cma; do \
	  	cp -v $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/overlays/$$i*.dtbo $(BINARIES_DIR)/rpi-firmware/overlays; \
                cp -v $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/overlays/$$i*.dtbo $(TARGET_DIR)/usr/lib/firmware/rpi/overlays; \
        done
        cd $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/; for i in $(PIOVERLAYS) ; do \
                cp -v $$i $(BINARIES_DIR); \
		cp -v $$i $(TARGET_DIR)/usr/lib/firmware/rpi; \
	done
        # Copy firmware
        cd $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot; for i in fixup.dat start.elf; do \
                cp -v $$i $(BINARIES_DIR); \
		cp -v $$i $(TARGET_DIR)/usr/lib/firmware/rpi; \
	done

endef

$(eval $(generic-package))
