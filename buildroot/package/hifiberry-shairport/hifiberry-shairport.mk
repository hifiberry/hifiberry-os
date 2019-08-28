################################################################################
#
# hifiberry-shairport
#
################################################################################

define HIFIBERRY_SHAIRPORT_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-shairport/shairport-sync.service \
                $(TARGET_DIR)/usr/lib/systemd/system/shairport-sync.service
        ln -fs ../../../usr/lib/systemd/system/shairport-sync.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/shairport-sync.service
endef

$(eval $(generic-package))
