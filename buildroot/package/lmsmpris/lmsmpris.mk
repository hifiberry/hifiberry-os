################################################################################
#
# lmsmpris
#
################################################################################

LMSMPRIS_VERSION = 7994fba5f1391231980ecbfca04fb4049730090f
LMSMPRIS_SITE = $(call github,hifiberry,lmsmpris,$(LMSMPRIS_VERSION))

define LMSMPRIS_BUILD_CMDS
endef

define LMSMPRIS_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/lmsmpris
        cp -rv $(@D)/* $(TARGET_DIR)/opt/lmsmpris
endef

define LMSMPRIS_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/lmsmpris/lmsmpris.service \
           $(TARGET_DIR)/usr/lib/systemd/system/lmsmpris.service
    ln -fs ../../../../usr/lib/systemd/system/lmsmpris.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/lmsmpris.service
endef

$(eval $(generic-package))
