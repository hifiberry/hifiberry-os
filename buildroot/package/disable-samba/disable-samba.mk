################################################################################
#
# disable-samba
#
################################################################################

DISABLE_SAMBE_DEPENDENCIES = samba

define DISABLE_SAMBA_INSTALL_IMAGES_CMDS
 	echo "Removing SAMBA services"
	for s in smb nmb winbind samba; do \
        	if [ -h $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/$$s.service ]; then \
                	echo "removing $$s.service in /etc/systemd/system/multi-user.target.wants"; \
                	rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/$$s.service; \
		fi; \
		if [ -f $(TARGET_DIR)/lib/systemd/system/$$s.service ]; then \
                        echo "removing $$s.service in /lib/systems/system"; \
                        rm $(TARGET_DIR)/lib/systemd/system/$$s.service; \
                fi; \
	done
endef

DISABLE_SAMBA_INSTALL_TARGET_CMDS = $(DISABLE_SAMBA_INSTALL_IMAGES_CMDS)

$(eval $(generic-package))

