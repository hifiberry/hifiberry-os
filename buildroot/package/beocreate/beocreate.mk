################################################################################
#
# beocreate
#
################################################################################

BEOCREATE_VERSION = c771c7a03217d15a171ea89d7b3f1847d85c75e2
BEOCREATE_SITE = $(call github,bang-olufsen,create,$(BEOCREATE_VERSION))

define BEOCREATE_BUILD_CMDS
endef

define BEOCREATE_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/beocreate
	mkdir -p $(TARGET_DIR)/etc/beocreate
        cp -rv $(@D)/Beocreate2/beo-system $(TARGET_DIR)/opt/beocreate
	cp -rv $(@D)/Beocreate2/beo-extensions $(TARGET_DIR)/opt/beocreate
	cp -rv $(@D)/beocreate_essentials $(TARGET_DIR)/opt/beocreate
	cp -rv $(@D)/Beocreate2/etc/* $(TARGET_DIR)/etc/beocreate
endef

define BEOCREATE_INSTALL_INIT_SYSTEMD
	cp -rv $(@D)/beocreate2.service $(TARGET_DIR)/usr/lib/systemd/system/beocreate2.service
    ln -fs ../../../../usr/lib/systemd/system/beocreate2.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/beocreate2.service
endef

$(eval $(generic-package))
