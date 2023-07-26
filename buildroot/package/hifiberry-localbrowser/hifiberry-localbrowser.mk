################################################################################
#
# hifiberry-localbrowser
#
################################################################################


define HIFIBERRY_LOCALBROWSER_BUILD_CMDS
endef

define HIFIBERRY_LOCALBROWSER_INSTALL_TARGET_CMDS
    # Local browser indication
    mkdir -p $(TARGET_DIR)/etc/hifiberry
    touch $(TARGET_DIR)/etc/hifiberry/localui.feature
endef

define HIFIBERRY_LOCALBROWSER_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-localbrowser/cog.service \
           $(TARGET_DIR)/usr/lib/systemd/system/cog.service
    mkdir -p $(TARGET_DIR)/lib/systemd/system-preset
endef

$(eval $(generic-package))
