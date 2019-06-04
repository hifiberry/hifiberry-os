################################################################################
#
# HIFIBERRY_TEST
#
################################################################################

define HIFIBERRY_TEST_INSTALL_TARGET_CMDS
	echo "HiFiBerry Test"
	[ -d $(TARGET_DIR)/opt/hifiberry/contrib ] || mkdir -p $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/dspdac.xml \
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/dacadcaddon-test.xml \
           $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/hifiberry-dacplusadc.dtbo \
           $(TARGET_DIR)/opt/hifiberry/contrib
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDAC
	echo "Installing DAC+ DSP test script"
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacdsp \
		$(TARGET_DIR)/etc/init.d/S99testdacdsp

	echo "Adding drivers to config.txt"
	echo "dtoverlay=hifiberry-dac" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDACADC
        echo "Installing DAC+ DSP DAC/ADC test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacdspadc \
                $(TARGET_DIR)/etc/init.d/S99testdacdspadc

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dac" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADC
        echo "Installing DAC+ ADC test script"
	mkdir -p $(TARGET_DIR)/boot/overlays/
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacadc \
                $(TARGET_DIR)/etc/init.d/S99testdacadc
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/hifiberry-dacplusadc.dtbo \
                $(TARGET_DIR)/boot/overlays/

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dacplusadc" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADC
        echo "Installing USB2I2S test script"
        mkdir -p $(TARGET_DIR)/opt/hifiberry/bin
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testusb \
                $(TARGET_DIR)/etc/init.d/S99testusb
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/spi_flash \
                $(TARGET_DIR)/opt/hifiberry/bin/
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/hbfw_usb2i2s_100.bin \
		$(TARGET_DIR)/opt/hifiberry/bin/

        echo "Adding drivers to config.txt"
        echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef


ifdef HIFIBERRY_TEST_DSPDAC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDAC
endif

ifdef HIFIBERRY_TEST_DSPDACADC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDACADC
endif

ifdef HIFIBERRY_TEST_DACADC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADC
endif

ifdef HIFIBERRY_TEST_USB
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_USB
endif





$(eval $(generic-package))

