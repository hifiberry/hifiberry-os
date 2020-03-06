################################################################################
#
# dlnampris
#
################################################################################

DLNAMPRIS_VERSION = 159198bd974f089d6e4a9f8b5b15d8a696f87b88
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
    ln -fs ../../../../usr/lib/systemd/system/dlnampris.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/dlnampris.service
endef

$(eval $(generic-package))
