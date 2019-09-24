################################################################################
#
# hifiberry-updater
#
################################################################################

define HIFIBERRY_UPDATER_INSTALL_TARGET_CMDS
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/update \
                $(TARGET_DIR)/opt/hifiberry/bin
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/extract-update \
                $(TARGET_DIR)/opt/hifiberry/bin
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/partitions \
                $(TARGET_DIR)/opt/hifiberry/bin
        $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/VERSION \
                $(TARGET_DIR)/etc/hifiberry.version
        $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/PIVERSION \
                $(TARGET_DIR)/etc/raspberrypi.version

endef

define HIFIBERRY_UPDATER_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
