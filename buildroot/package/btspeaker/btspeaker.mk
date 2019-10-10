################################################################################
#
# btspeaker
#
################################################################################

define BTSPEAKER_BUILD_CMDS
endef

define BTSPEAKER_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/main.conf \
           $(TARGET_DIR)/etc/bluetooth/main.conf
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/a2dp-agent.py \
           $(TARGET_DIR)/opt/btspeaker/a2dp-agent.py
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/btspeaker.sh \
           $(TARGET_DIR)/opt/btspeaker/btspeaker.sh
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/btuart.sh \
           $(TARGET_DIR)/opt/btspeaker/btuart.sh
endef

define BTSPEAKER_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/S99btspeaker \
                $(TARGET_DIR)/etc/init.d/S99btspeaker

endef

define BTSPEAKER_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/bluetoothd.service \
                $(TARGET_DIR)/lib/systemd/system/bluetoothd.service
        ln -fs ../../../../etc/systemd/system/bluetoothd.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/bluetoothd.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/btinterface.service \
                $(TARGET_DIR)/lib/systemd/system/btinterface.service
        ln -fs ../../../../etc/systemd/system/btinterface.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/btinterface.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/a2dp-agent.service \
                $(TARGET_DIR)/lib/systemd/system/a2dp-agent.service
        ln -fs ../../../../usr/lib/systemd/system/a2dp-agent.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/a2dp-agent.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/bluealsa.service \
                $(TARGET_DIR)/lib/systemd/system/bluealsa.service
        ln -fs ../../../../usr/lib/systemd/system/bluealsa.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/bluealsa.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/bluealsa-aplay.service\
                $(TARGET_DIR)/usr/lib/systemd/system/bluealsa-aplay.service
        ln -fs ../../../../usr/lib/systemd/system/bluealsa-aplay.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/bluealsa-aplay.service
endef

# Overwrite original Bluez5 package to make sure it doesn't install in systemd
define BLUEZ5_UTILS_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
