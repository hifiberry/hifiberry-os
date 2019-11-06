################################################################################
#
# hifiberry-measurements
#
################################################################################

define HIFIBERRY_MEASUREMENTS_INSTALL_TARGET_CMDS
endef

define HIFIBERRY_POSTGRES_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
