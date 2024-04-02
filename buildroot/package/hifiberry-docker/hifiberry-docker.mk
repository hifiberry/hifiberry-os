################################################################################
#
# hifiberry-docker
#
################################################################################

define HIFIBERRY_DOCKER_INSTALL_IMAGES_CMDS
	- ln -s ../lib/docker/cli-plugins/docker-compose $(TARGET_DIR)/usr/bin/docker-compose
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-docker/start-containers \
                $(TARGET_DIR)/opt/hifiberry/bin
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-docker/fix-avahi-ip \
		$(TARGET_DIR)/opt/hifiberry/bin

 	echo "Disabling docker by default"
	echo "disable docker.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-docker.preset 
endef

define HIFIBERRY_DOCKER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-docker/containers.service \
                $(TARGET_DIR)/lib/systemd/system/containers.service
	# Overwrite original docker.service file
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-docker/docker.service \
                $(TARGET_DIR)/lib/systemd/system/docker.service
endef

define HIFIBERRY_DOCKER_INSTALL_EXTRA_FILES
        mkdir -p $(TARGET_DIR)/etc/docker
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-docker/daemon.json \
                $(TARGET_DIR)/etc/docker/daemon.json
endef

HIFIBERRY_DOCKER_INSTALL_TARGET_CMDS = $(HIFIBERRY_DOCKER_INSTALL_IMAGES_CMDS)
HIFIBERRY_DOCKER_INSTALL_TARGET_CMDS += $(HIFIBERRY_DOCKER_INSTALL_EXTRA_FILES)

$(eval $(generic-package))

