################################################################################
#
# hifiberry-docker
#
################################################################################

define HIFIBERRY_DOCKER_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-docker/start-containers \
                $(TARGET_DIR)/opt/hifiberry/bin

 	echo "Disabling docker by default"
	echo "disable docker.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-docker.preset 
endef

define HIFIBERRY_DOCKER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-docker/containers.service \
                $(TARGET_DIR)/lib/systemd/system/containers.service
endef

HIFIBERRY_DOCKER_INSTALL_TARGET_CMDS = $(HIFIBERRY_DOCKER_INSTALL_IMAGES_CMDS)

$(eval $(generic-package))

