################################################################################
#
# configtxt
#
################################################################################

CONFIGTXT_DEPENDENCIES = rpi-firmware

define CONFIGTXT_INSTALL_TARGET_CMDS
        echo "# Enable I2C and SPI" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=i2c=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define CONFIGTXT_EEPROM_WORKAROUND
	echo "# Workaround force_eeprom_read" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define CONFIGTXT_ENABLE_EEPROM_I2C
	echo "dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define CONFIGTXT_BASE
#	echo "start_file=start4.elf" >> $(BINARIES_DIR)/rpi-firmware/config.txt
#	echo "fixup_file=fixup4.dat" >> $(BINARIES_DIR)/rpi-firmware/config.txt
        sed -i '/kernel=/d' $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "kernel=Image" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef



define CONFIGTXT_QUIET_INSTALL_TARGET_CMDS
 	echo "INstalling quiet cmdline.txt"
        $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/configtxt/cmdline.quiet \
                $(BINARIES_DIR)/rpi-firmware/cmdline.txt
endef

define CONFIGTXT_VERBOSE_INSTALL_TARGET_CMDS
	echo "Installing verbose cmdline.txt"
        $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/configtxt/cmdline.verbose \
                $(BINARIES_DIR)/rpi-firmware/cmdline.txt
endef

CONFIGTXT_POST_INSTALL_TARGET_HOOKS += CONFIGTXT_BASE

ifeq ($(BR2_PACKAGE_CONFIGTXT_QUIET),y)
CONFIGTXT_POST_INSTALL_TARGET_HOOKS += CONFIGTXT_QUIET_INSTALL_TARGET_CMDS
else
CONFIGTXT_POST_INSTALL_TARGET_HOOKS += CONFIGTXT_VERBOSE_INSTALL_TARGET_CMDS
endif

ifeq ($(BR2_PACKAGE_CONFIGTXT_EEPROM),y)
CONFIGTXT_POST_INSTALL_TARGET_HOOKS += CONFIGTXT_EEPROM_WORKAROUND
endif

# Enable EEPROM software I2C
CONFIGTXT_POST_INSTALL_TARGET_HOOKS += CONFIGTXT_ENABLE_EEPROM_I2C

$(eval $(generic-package))

