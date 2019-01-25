################################################################################
#
# initial-config
#
################################################################################

define INITIAL_CONFIG_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/initial-config/S40initialconfig \
                $(TARGET_DIR)/etc/init.d/
endef

$(eval $(generic-package))
