################################################################################
#
# lmsmpris
#
################################################################################

LMSMPRIS_VERSION = fa94bda910e2f28b1581d9f19d69cb93639e1863
LMSMPRIS_SITE = $(call github,hifiberry,lmsmpris,$(LMSMPRIS_VERSION))

define LMSMPRIS_BUILD_CMDS
endef

define LMSMPRIS_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/lmsmpris
        cp -rv $(@D)/* $(TARGET_DIR)/opt/lmsmpris
endef

define LMSMPRIS_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/lmsmpris/lmsmpris.service \
		$(TARGET_DIR)/usr/lib/systemd/system/lmsmpris.service
	mkdir -p $(TARGET_DIR)/lib/systemd/system-preset
	echo "disable lmsmpris.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-lmsmpris.preset
endef

$(eval $(generic-package))
