################################################################################
#
# HIFIBERRY_TEST
#
################################################################################

define HIFIBERRY_TEST_INSTALL_TARGET_CMDS
	echo "HiFiBerry Test"
	[ -d $(TARGET_DIR)/opt/hifiberry/contrib ] || mkdir -p $(TARGET_DIR)/opt/hifiberry/contrib
#        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/4way-iir.xml
#           $(TARGET_DIR)/opt/hifiberry/contrib
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDAC
	echo "Installing DAC+ DSP test script"
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacdsp \
		$(TARGET_DIR)/etc/init.d/S99testdacdsp
endef

ifdef HIFIBERRY_TEST_DSPDAC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDAC
endif

$(eval $(generic-package))

