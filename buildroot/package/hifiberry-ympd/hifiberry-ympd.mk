################################################################################
#
# hifiberry-ympd
#
################################################################################

#define HIFIBERRY_YMPD_INSTALL_TARGET_CMDS
#	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/ympd/ympd-bin \
#                $(TARGET_DIR)/usr/bin/ympd
#endef

define HIFIBERRY_YMPD_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-ympd/ympd.service \
                $(TARGET_DIR)/usr/lib/systemd/system/ympd.service
        ln -fs ../../../../usr/lib/systemd/system/ympd.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/ympd.service
endef

$(eval $(generic-package))
