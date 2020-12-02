################################################################################
#
# pigpiod-systemd
#
################################################################################

define PIGPIOD_SYSTEMD_INSTALL_INIT_SYSTEMD
        # Overwrite default pigpiod file
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/pigpiod-systemd/pigpiod.service \
                $(TARGET_DIR)/usr/lib/systemd/system/pigpio.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/pigpiod-systemd/start-pigpiod \
                $(TARGET_DIR)/opt/hifiberry/bin/start-pigpiod
	
endef

$(eval $(generic-package))
