################################################################################
#
# hifiberry-localbrowser
#
################################################################################


define HIFIBERRY_LOCALBROWSER_BUILD_CMDS
endef

define HIFIBERRY_LOCALBROWSER_INSTALL_TARGET_CMDS
    [ -d $(TARGET_DIR)/usr/lib/fonts ] || mkdir -p $(TARGET_DIR)/usr/lib/fonts
    -cd $(TARGET_DIR)/usr/lib/fonts ; \
     ln -s ../../share/fonts/*/*.ttf . 

    # Add VC4 overlay
    sed -i s/.*vc4-kms-v3d.*//g $(BINARIES_DIR)/rpi-firmware/config.txt
    echo "dtoverlay=vc4-kms-v3d,audio=off" >> $(BINARIES_DIR)/rpi-firmware/config.txt
    # Copy local VC4 DT file with "audio" option 
    cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-localbrowser/vc4-kms-v3d.dtbo \
	    $(BINARIES_DIR)/rpi-firmware/overlays

    # Make sure it gets registered in systemd
    cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-localbrowser/60-drm.rules \
	    $(TARGET_DIR)/usr/lib/udev/rules.d/60-drm.rules

endef

define HIFIBERRY_LOCALBROWSER_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-localbrowser/weston.service \
           $(TARGET_DIR)/usr/lib/systemd/system/weston.service
    ln -fs ../../../../usr/lib/systemd/system/weston.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/weston.service
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-localbrowser/cog.service \
           $(TARGET_DIR)/usr/lib/systemd/system/cog.service
    ln -fs ../../../../usr/lib/systemd/system/cog.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/cog.service
endef

$(eval $(generic-package))
