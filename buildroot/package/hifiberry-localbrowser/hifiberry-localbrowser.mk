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
endef

define HIFIBERRY_LOCALBROWSER_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-localbrowser/localbrowser.service \
           $(TARGET_DIR)/usr/lib/systemd/system/localbrowser.service
    ln -fs ../../../../usr/lib/systemd/system/localbrowser.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/localbrowser.service
endef

$(eval $(generic-package))
