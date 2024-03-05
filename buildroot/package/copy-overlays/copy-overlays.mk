################################################################################
#
# copy-overlays
#
################################################################################


COPY_OVERLAYS_DEPENDENCIES = rpi-firmware linux

define COPY_OVERLAYS_INSTALL_TARGET_CMDS
	# Copy overlays
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/rpi/overlays
	rm $(BINARIES_DIR)/rpi-firmware/overlays/*
        for i in hifiberry vc4 i2c-gpio gpio-ir cma dwc disable rpi- spi i2c uart; do \
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
