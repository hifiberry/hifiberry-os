################################################################################
#
# disable-samba
#
################################################################################

DISABLE_SAMBE_DEPENDENCIES = samba

define DISABLE_SAMBA_INSTALL_IMAGES_CMDS
	mkdir -p $(TARGET_DIR)/lib/systemd/system-preset

 	echo "Removing SAMBA services"
	for s in smb nmb winbind samba; do \
		echo "disable $s.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-samba.preset ; \
	done
endef

DISABLE_SAMBA_INSTALL_TARGET_CMDS = $(DISABLE_SAMBA_INSTALL_IMAGES_CMDS)

$(eval $(generic-package))

