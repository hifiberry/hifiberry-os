################################################################################
#
# hifiberry-systemd
#
################################################################################

define HIFIBERRY_SYSTEMD_INSTALL_TARGET_CMDS
 	echo "Speed up network-online"
	#sed -i "s/ExecStart.*/ExecStart=\/usr\/lib\/systemd\/systemd-networkd-wait-online\ --timeout=20/" \
	#	$(TARGET_DIR)/usr/lib/systemd/system/systemd-networkd-wait-online.service
endef

$(eval $(generic-package))

