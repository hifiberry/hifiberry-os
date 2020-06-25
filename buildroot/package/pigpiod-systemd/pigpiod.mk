################################################################################
#
# pigpiod-systemd
#
################################################################################

define PIGPIOD_SYSTEMD_INSTALL_INIT_SYSTEMD
	mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/pigpiod-systemd/pigpiod.service \
                $(TARGET_DIR)/usr/lib/systemd/system/pigpiod.service
        ln -fs ../../../../usr/lib/systemd/system/pigpiod.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/pigpiod.service
endef

$(eval $(generic-package))
