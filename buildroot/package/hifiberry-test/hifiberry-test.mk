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
        $(INSTALL) -D -m 0700 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/hbflash.sh \
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/dacplusadcpro.eep \
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/dacplus.eep \
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/digiplus.eep \
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/digipro.eep \
           $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/dac2hd.eep \
	   $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0700 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/dtoverlay \
           $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0700 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/flash.sh \
	   $(TARGET_DIR)/opt/hifiberry/contrib
endef


define HIFIBERRY_TEST_INSTALL_INIT_SYSV_AMP2
        echo "Installing Amp2 test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testamp2 \
                $(TARGET_DIR)/etc/init.d/S99testamp2

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dacplus" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDAC
	echo "Installing DAC+ DSP test script"
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacdsp \
		$(TARGET_DIR)/etc/init.d/S99testdacdsp

	echo "Adding drivers to config.txt"
	echo "dtoverlay=hifiberry-dac" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACRTC
        echo "Installing DAC+ RTC test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacrtc \
                $(TARGET_DIR)/etc/init.d/S99testdacrtc

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dac" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=i2c-rtc,ds1307" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_arm=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
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
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADCPRO
        echo "Installing DAC+ ADC Pro test script"
        mkdir -p $(TARGET_DIR)/boot/overlays/
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacadcpro \
                $(TARGET_DIR)/etc/init.d/S99testdacadcpro
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/hifiberry-dacplusadcpro.dtbo \
                $(TARGET_DIR)/boot/overlays/

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dacplusadcpro" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef


define HIFIBERRY_TEST_INSTALL_INIT_SYSV_USB
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


ifdef HIFIBERRY_TEST_AMP2
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_AMP2
endif

ifdef HIFIBERRY_TEST_DACRTC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACRTC
endif

ifdef HIFIBERRY_TEST_DSPDAC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDAC
endif

ifdef HIFIBERRY_TEST_DSPDACADC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDACADC
endif

ifdef HIFIBERRY_TEST_DACADC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADC
endif

ifdef HIFIBERRY_TEST_DACADCPRO
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADCPRO
endif

ifdef HIFIBERRY_TEST_USB
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_USB
endif

$(eval $(generic-package))

