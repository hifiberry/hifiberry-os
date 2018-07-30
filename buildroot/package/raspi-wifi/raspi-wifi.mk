################################################################################
#
# raspi-wifi
#
################################################################################

RASPI_WIFI_VERSION = master
#RASPI_WIFI_SITE = $(call github,jasbur,RaspiWiFi,$(RASPI_WIFI_VERSION))

RASPI_WIFI_DEPENDENCIES = host-cargo

define RASPI_WIFI_BUILD_CMDS
endef

define RASPI_WIFI_INSTALL_TARGET_CMDS
endef

define RASPI_WIFI_INSTALL_INIT_SYSV
endef

define DSPTOOLKIT_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
