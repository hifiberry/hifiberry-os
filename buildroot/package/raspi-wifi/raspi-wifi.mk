################################################################################
#
# raspi-wifi
#
################################################################################

define RASPI_WIFI_BUILD_CMDS
endef

define RASPI_WIFI_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/interfaces \
           $(TARGET_DIR)/etc/network/interfaces.bak
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/hostapd.conf \
           $(TARGET_DIR)/etc/tempap-hostapd.conf
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/dnsmasq.conf \
           $(TARGET_DIR)/etc/tempap-dnsmasq.conf
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/wpa_supplicant.conf \
           $(TARGET_DIR)/etc/wpa_supplicant.conf
    # Disable stub resolver in systemd resolved
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/resolved.conf \
           $(TARGET_DIR)/etc/systemd/resolved.conf
endef

define RASPI_WIFI_INSTALL_INIT_SYSV
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/S30copy-wifi-config \
           $(TARGET_DIR)/etc/init.d/
endef

define RASPI_WIFI_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/wireless.network \
           $(TARGET_DIR)/etc/systemd/network/wireless.network
    $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/wpa_supplicant@wlan0.service \
           $(TARGET_DIR)/usr/lib/systemd/system/wpa_supplicant@wlan0.service
    ln -fs ../../../../usr/lib/systemd/system/wpa_supplicant@wlan0.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service
    $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/tempap-dnsmasq.service \
           $(TARGET_DIR)/usr/lib/systemd/system/tempap-dnsmasq.service
    $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/tempap-hostapd.service \
           $(TARGET_DIR)/usr/lib/systemd/system/tempap-hostapd.service
    $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/tempap.service \
           $(TARGET_DIR)/usr/lib/systemd/system/tempap.service
endef

$(eval $(generic-package))
