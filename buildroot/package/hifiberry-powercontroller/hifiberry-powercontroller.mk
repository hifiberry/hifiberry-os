################################################################################
#
# hifiberry-powercontroller
#
################################################################################

define HIFIBERRY_POWERCONTROLLER_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-powercontroller/pc-write \
                $(TARGET_DIR)/opt/hifiberry/bin
    sleep 10
endef

define HIFIBERRY_POWERCONTROLLER_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-powercontroller/pc-startup.service \
                $(TARGET_DIR)/lib/systemd/system
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-powercontroller/pc-startup-finish.service \
                $(TARGET_DIR)/lib/systemd/system
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-powercontroller/pc-shutdown.service \
		$(TARGET_DIR)/lib/systemd/system
endef

$(eval $(generic-package))
