################################################################################
#
# hifiberry-alsaloop
#
################################################################################

define HIFIBERRY_ALSALOOP_INSTALL_TARGET_CMDS
endef

define HIFIBERRY_ALSALOOP_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-alsaloop/alsaloop.service \
                $(TARGET_DIR)/usr/lib/systemd/system/alsaloop.service
        ln -fs ../../../../usr/lib/systemd/system/alsaloop.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/alsaloop.service
endef

$(eval $(generic-package))
