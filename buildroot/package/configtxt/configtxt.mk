################################################################################
#
# configtxt
#
################################################################################

CONFIGTXT_DEPENDENCIES = rpi-firmware

define CONFIGTXT_INSTALL_TARGET_CMDS
	sed -i '/dtparam=i2c/d' $(BINARIES_DIR)/rpi-firmware/config.txt
	sed -i '/dtparam=spi/d' $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=i2c=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtparam=spi=on" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define CONFIGTXT_EEPROM_WORKAROUND
	sed -i '/force_eeprom_read/d' $(BINARIES_DIR)/rpi-firmware/config.txt
        echo "force_eeprom_read=0" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define CONFIGTXT_ENABLE_EEPROM_I2C
	sed -i '/dtoverlay=i2c-gpio/d' $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define CONFIGTXT_BASE
        sed -i '/kernel=/d' $(BINARIES_DIR)/rpi-firmware/config.txt
	echo "kernel=Image" >> $(BINARIES_DIR)/rpi-firmware/config.txt
endef

define CONFIGTXT_REMOVESTUFF
	sed -i '/imx219/d' $(BINARIES_DIR)/rpi-firmware/config.txt
	sed -i '/ov5647/d' $(BINARIES_DIR)/rpi-firmware/config.txt
endef



define CONFIGTXT_QUIET_INSTALL_TARGET_CMDS
 	echo "Installing quiet cmdline.txt"
        $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/configtxt/cmdline.quiet \
                $(BINARIES_DIR)/rpi-firmware/cmdline.txt
endef

define CONFIGTXT_VERBOSE_INSTALL_TARGET_CMDS
	echo "Installing verbose cmdline.txt"
        $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/configtxt/cmdline.verbose \
                $(BINARIES_DIR)/rpi-firmware/cmdline.txt
endef

CONFIGTXT_POST_INSTALL_TARGET_HOOKS += CONFIGTXT_REMOVESTUFF CONFIGTXT_BASE

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

