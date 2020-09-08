################################################################################
#
# enable-vc4kms
#
################################################################################


COPY_OVERLAYS_DEPENDENCIES = rpi-firmware linux

define COPY_OVERLAYS_INSTALL_TARGET_CMDS
	echo "Copying overlays"
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/rpi/overlays
        for i in hifiberry vc4; do \
	  	cp -v $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/overlays/$$i*.dtbo $(BINARIES_DIR)/rpi-firmware/overlays; \
                cp -v $(BUILD_DIR)/linux-custom/arch/arm/boot/dts/overlays/$$i*.dtbo $(TARGET_DIR)/usr/lib/firmware/rpi/overlays; \
        done
endef

$(eval $(generic-package))
