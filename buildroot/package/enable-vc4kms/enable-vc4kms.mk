################################################################################
#
# enable-vc4kms
#
################################################################################


define ENABLE_VC4KMS_INSTALL_TARGET_CMDS
    # Add VC4 overlay
    sed -i s/.*vc4-kms-v3d.*//g $(BINARIES_DIR)/rpi-firmware/config.txt
    echo "dtoverlay=vc4-kms-v3d,audio=off" >> $(BINARIES_DIR)/rpi-firmware/config.txt
    # Copy local VC4 DT file with "audio" option 
    -mkdir -p $(TARGET_DIR)/boot/overlays
    cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/enable-vc4kms/vc4-kms-v3d.dtbo \
	    $(BINARIES_DIR)/rpi-firmware/overlays
    cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/enable-vc4kms/vc4-kms-v3d.dtbo \
            $(TARGET_DIR)/boot/overlays

    # Make sure it gets registered in systemd
    cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/enable-vc4kms/60-drm.rules \
	    $(TARGET_DIR)/usr/lib/udev/rules.d/60-drm.rules
endef

$(eval $(generic-package))
