################################################################################
#
# watchdog
#
################################################################################

define WATCHDOG_INSTALL_TARGET_CMDS
	[ -d $(TARGET_DIR)/opt/hifiberry/bin ] || mkdir $(TARGET_DIR)/opt/hifiberry/bin
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/watchdog/watchdog.py \
           $(TARGET_DIR)/opt/hifiberry/bin/watchdog
endef

define WATCHDOG_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/watchdog/watchdog.service \
                $(TARGET_DIR)/usr/lib/systemd/system/watchdog.service
        if [ -d $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants ]; then \
          ln -fs ../../../../usr/lib/systemd/system/watchdog.service \
                  $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/watchdog.service; \
        fi
endef

$(eval $(generic-package))
