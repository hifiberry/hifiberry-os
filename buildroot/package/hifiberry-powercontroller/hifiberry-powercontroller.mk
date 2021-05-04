################################################################################
#
# hifiberry-powercontroller
#
################################################################################

PC_VERSION=r5
PC_BINARY=powercontrol.ino_atmega808_16000000L.hex
PC_DOWNLOAD=https://github.com/hifiberry/powercontroller/releases/download/$(PC_VERSION)/$(PC_BINARY)

define HIFIBERRY_POWERCONTROLLER_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-powercontroller/pc-write \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-powercontroller/write-firmware \
                $(TARGET_DIR)/opt/hifiberry/powercontroller/write-firmware
    curl -L $(PC_DOWNLOAD) --output $(TARGET_DIR)/opt/hifiberry/powercontroller/firmware-$(PC_VERSION).hex
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
