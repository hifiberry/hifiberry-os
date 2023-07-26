################################################################################
#
# hifiberry-weston
#
################################################################################


define HIFIBERRY_WESTON_BUILD_CMDS
endef

define HIFIBERRY_WESTON_INSTALL_TARGET_CMDS
    # Weston config
    install -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-weston/weston.ini \
            $(TARGET_DIR)/etc/xdg/weston/weston.ini
    # Local browser indication
    mkdir -p $(TARGET_DIR)/etc/hifiberry
    touch $(TARGET_DIR)/etc/hifiberry/localui.feature
endef

define HIFIBERRY_WESTON_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-weston/weston.service \
           $(TARGET_DIR)/usr/lib/systemd/system/weston.service
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-weston/enable-vc \
	   $(TARGET_DIR)/opt/hifiberry/bin/enable-vc
    mkdir -p $(TARGET_DIR)/lib/systemd/system-preset
endef

$(eval $(generic-package))
