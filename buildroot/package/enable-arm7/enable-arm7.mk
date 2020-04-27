################################################################################
#
# enable-arm7
#
################################################################################


define ENABLE_ARM7_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/etc/features
	touch $(TARGET_DIR)/etc/features/arm7

endef

$(eval $(generic-package))
