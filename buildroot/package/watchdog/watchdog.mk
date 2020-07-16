################################################################################
#
# watchdog
#
################################################################################

WATCHDOG_VERSION = d78bde3c9f00f39e07c1989cb8b22358a81a9020
WATCHDOG_SITE = $(call github,hifiberry,watchdog,$(WATCHDOG_VERSION))

					
define WATCHDOG_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/opt/watchdog
        cp -rv $(@D)/* $(TARGET_DIR)/opt/watchdog
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/watchdog/watchdog.conf \
		$(TARGET_DIR)/etc/watchdog.conf
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/watchdog/watchdog.sh \
		$(TARGET_DIR)/opt/watchdog
endef

define WATCHDOG_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/watchdog/watchdog.service \
                $(TARGET_DIR)/usr/lib/systemd/system/watchdog.service
endef

$(eval $(generic-package))
