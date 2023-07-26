################################################################################
#
# HIFIBERRY_TEST
#
################################################################################

define HIFIBERRY_TEST_INSTALL_TARGET_CMDS
	echo "HiFiBerry Test"
	[ -d $(TARGET_DIR)/opt/hifiberry/contrib ] || mkdir -p $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0700 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/hbflash.sh \
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/dspdac.xml \
           $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/4output.xml \
	   $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/amp100.eep \
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
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/dac2pro.eep \
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/digi2pro.eep \
           $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/digi2standard.eep \
           $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/beocreate2.eep \
	   $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0700 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/dtoverlay \
           $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0700 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/flash.sh \
	   $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/eepdump \
	   $(TARGET_DIR)/usr/bin/eepdump
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/eeprom/eepmake \
  	   $(TARGET_DIR)/usr/bin/eepmake
	echo "kernel=zImage" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef


define HIFIBERRY_TEST_INSTALL_INIT_SYSV_AMP2
        echo "Installing Amp2 test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testamp2 \
                $(TARGET_DIR)/etc/init.d/S99testamp2

        echo "Adding drivers to config.txt"
	echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=hifiberry-dacplus" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_AMP100
        echo "Installing Amp100 test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testamp100 \
                $(TARGET_DIR)/etc/init.d/S99testamp100

        echo "Adding drivers to config.txt"
	echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=hifiberry-dacplus" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DAC2HD
        echo "Installing DAC2HD test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdac2hd \
                $(TARGET_DIR)/etc/init.d/S99testdac2hd

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dacplushd" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DAC2PRO
        echo "Installing DAC2Pro test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdac2pro \
                $(TARGET_DIR)/etc/init.d/S99testdac2pro

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dacplus" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DAC2PROXLR
        echo "Installing DAC2Pro test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdac2proxlr \
                $(TARGET_DIR)/etc/init.d/S99testdac2proxlr

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dacplus" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DIGI2PRO
        echo "Installing Digi2 Pro test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdigi2pro \
                $(TARGET_DIR)/etc/init.d/S99testdigi2pro

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-digi-pro" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DIGI2STANDARD
        echo "Installing Digi2 Standard test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdigi2standard \
                $(TARGET_DIR)/etc/init.d/S99testdigi2standard

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-digi" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPADDON
        echo "Installing DSP Add-on test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdspaddon \
                $(TARGET_DIR)/etc/init.d/S99testdspaddon
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/dsp-addon-96-11.xml \
		$(TARGET_DIR)/opt/hifiberry/contrib/dspaddon.xml

        echo "Adding drivers to config.txt"

	sed -i s/.*hifiberry.*//g $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=spi=on"  >> $(BINARIES_DIR)/rpi-firmware/config.txt
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

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_KADDSP
        echo "Installing KAD DSP test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testkaddsp \
                $(TARGET_DIR)/etc/init.d/S99testkaddsp

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dac" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_BEOCREATE
        echo "Installing Beocreate test script"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testbeocreate \
                $(TARGET_DIR)/etc/init.d/S99testbeocreate
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/beov10.xml \
		$(TARGET_DIR)/opt/hifiberry/contrib/beo.xml

        echo "Adding drivers to config.txt"
        echo "dtoverlay=i2c-gpio" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_sda=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "dtparam=i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
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

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADCPROXLR
        echo "Installing DAC+ ADC Stage+XLR test script"
        mkdir -p $(TARGET_DIR)/boot/overlays/
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testdacadcproxlr \
                $(TARGET_DIR)/etc/init.d/S99testdacadcproxlr
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/hifiberry-dacplusadcpro.dtbo \
                $(TARGET_DIR)/boot/overlays/
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/sine1k.wav \
                $(TARGET_DIR)/opt/hifiberry/contrib/sine1k.wav

        echo "Adding drivers to config.txt"
        echo "dtoverlay=hifiberry-dacplusadcpro" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define HIFIBERRY_TEST_INSTALL_INIT_SYSV_POWERCONTROLLER
        echo "Installing Power controller flasher"
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/S99testpowercontroller \
                $(TARGET_DIR)/etc/init.d/S99testpowercontroller
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-test/pc-firmware-2.hex \
		$(TARGET_DIR)/opt/hifiberry/contrib/firmware.hex
        echo "Adding drivers to config.txt"
	echo "# Enable I2C and serial" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=i2c=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "enable_uart=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtoverlay=disable-bt" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef



ifdef HIFIBERRY_TEST_AMP2
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_AMP2
endif

ifdef HIFIBERRY_TEST_AMP100
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_AMP100
endif

ifdef HIFIBERRY_TEST_DAC2HD
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DAC2HD
endif

ifdef HIFIBERRY_TEST_DAC2PRO
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DAC2PRO
endif

ifdef HIFIBERRY_TEST_DSPADDON
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPADDON
endif

ifdef HIFIBERRY_TEST_DACRTC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACRTC
endif

ifdef HIFIBERRY_TEST_DSPDAC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DSPDAC
endif

ifdef HIFIBERRY_TEST_DACADC
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADC
endif

ifdef HIFIBERRY_TEST_DACADCPRO
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADCPRO
endif

ifdef HIFIBERRY_TEST_DACADCPROXLR
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DACADCPROXLR
endif

ifdef HIFIBERRY_TEST_DIGI2PRO
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DIGI2PRO
endif

ifdef HIFIBERRY_TEST_DIGI2STANDARD
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_DIGI2STANDARD
endif

ifdef HIFIBERRY_TEST_KADDSP
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_KADDSP
endif

ifdef HIFIBERRY_TEST_BEOCREATE
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_BEOCREATE
endif

ifdef HIFIBERRY_TEST_POWERCONTROLLER
HIFIBERRY_TEST_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_TEST_INSTALL_INIT_SYSV_POWERCONTROLLER
endif

$(eval $(generic-package))

