################################################################################
#
# plexamp
#
################################################################################

PLEXAMP_DEPENDENCIES = beocreate

define PLEXAMP_INSTALL_TARGET_CMDS
    if [ -d $(TARGET_DIR)/opt/beocreate/beo-extensions/plexamp ]; then  \
    	rm -rf $(TARGET_DIR)/opt/beocreate/beo-extensions/plexamp; \
    fi
    cat $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/plexamp/extensions.conf \
        >> $(TARGET_DIR)/etc/extensions.conf
endef

$(eval $(generic-package))
