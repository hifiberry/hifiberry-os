################################################################################
#
# raat
#
################################################################################

define RAAT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raat/raat_app \
                $(TARGET_DIR)/opt/raat/raat_app
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raat/raatool \
                $(TARGET_DIR)/opt/raat/raatool
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raat/configure-raat \
                $(TARGET_DIR)/opt/raat/configure-raat
endef

define RAAT_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raat/raat.service \
                $(TARGET_DIR)/usr/lib/systemd/system/raat.service
endef

$(eval $(generic-package))
