################################################################################
#
# dlnampris
#
################################################################################

DLNAMPRIS_VERSION = f84b35a51760d313dc03f10b11186dae1d347cb3
DLNAMPRIS_SITE = $(call github,hifiberry,dlna-mpris,$(DLNAMPRIS_VERSION))

define DLNAMPRIS_BUILD_CMDS
endef

define DLNAMPRIS_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/dlnampris
        cp -rv $(@D)/* $(TARGET_DIR)/opt/dlnampris
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dlnampris/dlnampris.conf \
		           $(TARGET_DIR)/etc/dlnampris.conf
endef

define DLNAMPRIS_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dlnampris/dlnampris.service \
		$(TARGET_DIR)/usr/lib/systemd/system/dlnampris.service
	mkdir -p $(TARGET_DIR)/lib/systemd/system-preset
	echo "disable dlnampris.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-dlnampris.preset

endef

$(eval $(generic-package))
