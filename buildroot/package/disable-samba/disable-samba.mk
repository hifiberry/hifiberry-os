################################################################################
#
# disable-samba
#
################################################################################

define DISABLE_SAMBA_INSTALL_TARGET_CMDS
 	echo "Removing SAMBA services"
	if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/smb.service ]; then \
		rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/smb.service; \
	fi
	if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/nmb.service ]; then \
		rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/nmb.service; \
	fi
endef

$(eval $(generic-package))

