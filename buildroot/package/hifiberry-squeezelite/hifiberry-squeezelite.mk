################################################################################
#
# hifiberry-squeezelite
#
################################################################################

define HIFIBERRY_SQUEEZELITE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-squeezelite/S99squeezelite \
                $(TARGET_DIR)/etc/init.d/S99squeezelite
	mkdir -p $(TARGET_DIR)/var/squeezelite
	echo "HiFiBerry" > $(TARGET_DIR)/var/squeezelite/squeezelite.name
endef

$(eval $(generic-package))
