################################################################################
#
# pigpiod-systemd
#
################################################################################

define PIGPIOD_SYSTEMD_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/pigpiod-systemd/pigpiod.service \
                $(TARGET_DIR)/usr/lib/systemd/system/pigpiod.service
endef

$(eval $(generic-package))
