################################################################################
#
# raspi-wifi
#
################################################################################

#RASPI_WIFI_VERSION = master
#RASPI_WIFI_SITE = $(call github,jasbur,RaspiWiFi,$(RASPI_WIFI_VERSION))

#RASPI_WIFI_DEPENDENCIES = host-cargo

define RASPI_WIFI_BUILD_CMDS
endef

define RASPI_WIFI_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/interfaces \
           $(TARGET_DIR)/etc/network/interfaces.bak
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/copy-config \
           $(TARGET_DIR)/opt/hifiberry/bin/copy-config
endef

define RASPI_WIFI_INSTALL_INIT_SYSV
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/S30copy-wifi-config \
           $(TARGET_DIR)/etc/init.d/
endef

define RASPI_WIFI_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/copy-config.service \
           $(TARGET_DIR)/rsr/lib/systemd/system/copy-config.service
    ln -fs ../../../usr/lib/systemd/system/copy-config.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/copy-config.service
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/wireless.network \
           $(TARGET_DIR)/etc/systemd/network/wireless.network
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/wpa_supplicant@wlan0.service \
           $(TARGET_DIR)/usr/lib/systemd/system/wpa_supplicant@wlan0.service
    ln -fs ../../../../usr/lib/systemd/system/wpa_supplicant@wlan0.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service
#    ln -fs ../../../usr/lib/systemd/system/wpa_supplicant.service \
#           $(TARGET_DIR)/etc/systemd/system/dbus-fi.w1.wpa_supplicant1.service
#    ln -fs ../../../../usr/lib/systemd/system/wpa_supplicant.service \
#           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/wpa_supplicant.service

endef

$(eval $(generic-package))
