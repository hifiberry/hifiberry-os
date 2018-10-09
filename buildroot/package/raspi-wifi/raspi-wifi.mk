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
           $(TARGET_DIR)/etc/network/interfaces
endef

define RASPI_WIFI_INSTALL_INIT_SYSV
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/raspi-wifi/S30copy-wifi-config \
           $(TARGET_DIR)/etc/init.d/
endef

define DSPTOOLKIT_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
