################################################################################
#
# snapcastmpris
#
################################################################################

SNAPCASTMPRIS_VERSION = 333372d5368552cb295a11a34119c04ba581638b
SNAPCASTMPRIS_SITE = $(call github,hifiberry,snapcastmpris,$(SNAPCASTMPRIS_VERSION))

define SNAPCASTMPRIS_BUILD_CMDS
endef

define SNAPCASTMPRIS_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/snapcastmpris
        cp -rv $(@D)/* $(TARGET_DIR)/opt/snapcastmpris
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/snapcastmpris/snapcastmpris.conf \
           $(TARGET_DIR)/etc/snapcastmpris.conf
endef

define SNAPCASTMPRIS_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/snapcastmpris/snapcastmpris.service \
           $(TARGET_DIR)/usr/lib/systemd/system/snapcastmpris.service
    ln -fs ../../../../usr/lib/systemd/system/snapcastmpris.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/snapcastmpris.service
endef

$(eval $(generic-package))
