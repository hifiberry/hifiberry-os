################################################################################
#
# copy-overlays
#
################################################################################


COPY_OVERLAYS_DEPENDENCIES = rpi-firmware linux

define COPY_OVERLAYS_INSTALL_TARGET_CMDS
	echo "Copying overlays"
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/rpi/overlays
        for i in hifiberry vc4 i2c-gpio; do \
	  	cp -v $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/overlays/$$i*.dtbo $(BINARIES_DIR)/rpi-firmware/overlays; \
                cp -v $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/overlays/$$i*.dtbo $(TARGET_DIR)/usr/lib/firmware/rpi/overlays; \
        done
        for i in $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/bcm*rpi*.dtb; do \
		cp -v $$i $(BINARIES_DIR); \
	done
endef

$(eval $(generic-package))
