################################################################################
#
# btspeaker
#
################################################################################

define BTSPEAKER_BUILD_CMDS
endef

define BTSPEAKER_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/main.conf \
           $(TARGET_DIR)/etc/bluetooth/main.cf
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/a2dp-agent.py \
           $(TARGET_DIR)/opt/btspeaker/a2dp-agent.py

endef

define BTSPEAKER_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/S99btspeaker \
                $(TARGET_DIR)/etc/init.d/S99btspeaker

endef

define BTSPEAKER_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
