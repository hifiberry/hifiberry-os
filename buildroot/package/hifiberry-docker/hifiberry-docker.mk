################################################################################
#
# hifiberry-docker
#
################################################################################

define HIFIBERRY_DOCKER_INSTALL_IMAGES_CMDS
	mkdir -p $(TARGET_DIR)/lib/systemd/system-preset

 	echo "Disabling docker by default"
	echo "disable docker.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-docker.preset 
endef

HIFIBERRY_DOCKER_INSTALL_TARGET_CMDS = $(HIFIBERRY_DOCKER_INSTALL_IMAGES_CMDS)

$(eval $(generic-package))

