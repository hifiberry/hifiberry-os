################################################################################
#
# snapcastmpris
#
################################################################################

SNAPCASTMPRIS_VERSION = 6d1312498d7994f0660183e309f942327ddc7851
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
	mkdir -p $(TARGET_DIR)/lib/systemd/system-preset
		echo "disable snapcastmpris.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-snapcastmpris.preset
endef

$(eval $(generic-package))
