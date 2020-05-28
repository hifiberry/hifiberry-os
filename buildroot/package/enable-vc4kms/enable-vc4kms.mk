################################################################################
#
# enable-vc4kms
#
################################################################################


ENABLE_VC4KMS_DEPENDENCIES = rpi-firmware

define ENABLE_VC4KMS_INSTALL_TARGET_CMDS
    # Add VC4 overlay
    sed -i s/.*vc4-*kms-v3d.*//g $(BINARIES_DIR)/rpi-firmware/config.txt
    echo "dtoverlay=vc4-fkms-v3d,audio=off" >> $(BINARIES_DIR)/rpi-firmware/config.txt

    # Make sure it gets registered in systemd
    mkdir -p $(TARGET_DIR)/usr/lib/udev/rules.d
    cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/enable-vc4kms/60-drm.rules \
	    $(TARGET_DIR)/usr/lib/udev/rules.d/60-drm.rules

endef

$(eval $(generic-package))
