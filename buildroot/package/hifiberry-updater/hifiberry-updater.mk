################################################################################
#
# hifiberry-updater
#
################################################################################

HIFIBERRY_UPDATER_DEPENDENCIES = rpi-firmware systemd copy-overlays

define HIFIBERRY_UPDATER_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/var/spool/cron/crontabs
        echo "critical" > $(TARGET_DIR)/etc/updater.release
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/update \
                $(TARGET_DIR)/opt/hifiberry/bin
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/extract-update \
                $(TARGET_DIR)/opt/hifiberry/bin
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/update-firmware \
		$(TARGET_DIR)/opt/hifiberry/bin
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/partitions \
                $(TARGET_DIR)/opt/hifiberry/bin
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/reactivate-previous-release \
		$(TARGET_DIR)/opt/hifiberry/bin
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/backup-config \
                $(TARGET_DIR)/opt/hifiberry/bin
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/restore-config \
                $(TARGET_DIR)/opt/hifiberry/bin
        $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/VERSION \
                $(TARGET_DIR)/etc/hifiberry.version
        $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/PIVERSION \
                $(TARGET_DIR)/etc/raspberrypi.version
        $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/config-files \
                $(TARGET_DIR)/opt/hifiberry/etc/config-files
        $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/services \
                $(TARGET_DIR)/opt/hifiberry/etc/services
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/updater.service \
                $(TARGET_DIR)/usr/lib/systemd/system/updater.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/updater.timer \
	        $(TARGET_DIR)/usr/lib/systemd/system/updater.timer
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-updater/after-update \
                $(TARGET_DIR)/opt/hifiberry/bin
	echo "Installing updater"
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/../scripts/updater.sh $(TARGET_DIR)/tmp/updater.sh
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/../scripts/updater.sh $(TARGET_DIR)/updater.sh

endef

ifeq ($(BR2_aarch64),y)
define HIFIBERRY_UPDATER_INSTALL_KERNEL
     	echo "Installing 64bit kernel"
   	$(INSTALL) -D -m 0644 $(BUILD_DIR)/linux-custom/arch/arm64/boot/Image.gz $(TARGET_DIR)/usr/lib/firmware/rpi/zImage

endef
else
define HIFIBERRY_UPDATER_INSTALL_KERNEL
        echo "Installing 32bit kernel"
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/linux-custom/arch/arm/boot/zImage $(TARGET_DIR)/usr/lib/firmware/rpi

endef
endif

### 
### Add more functions to RPI firmware
###
ifeq ($(BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI4),y)
define HIFIBERRY_UPDATER_INSTALL_FIRMWARE
        echo "HiFiBerry updater: adding Pi4 firmware files to /usr/lib/firmware/rpi"
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot/start4.elf $(TARGET_DIR)/usr/lib/firmware/rpi/start.elf
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot/fixup4.dat $(TARGET_DIR)/usr/lib/firmware/rpi/fixup.dat
	$(INSTALL) -D -m 0644 $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot/bcm2711-rpi-4-b.dtb $(TARGET_DIR)/usr/lib/firmware/rpi/bcm2711-rpi-4-b.dtb

endef
else
define HIFIBERRY_UPDATER_INSTALL_FIRMWARE
        echo "HiFiBerry updater: adding Pi1-3 firmware files to /usr/lib/firmware/rpi"
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot/start.elf $(TARGET_DIR)/usr/lib/firmware/rpi/start.elf
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot/fixup.dat $(TARGET_DIR)/usr/lib/firmware/rpi/fixup.dat

endef
endif

define HIFIBERRY_UPDATER_INSTALL_ALL_OVERLAYS
        echo "Installing overlays"
	sleep 10
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/rpi/overlays
        for ovldtb in $(@D)/boot/overlays/*.dtbo; do \
                $(INSTALL) -D -m 0644 $${ovldtb} $(TARGET_DIR)/usr/lib/firmware/rpi/overlays/$${ovldtb##*/} || exit 1; \
        done
endef

HIFIBERRY_UPDATER_INSTALL_TARGET_CMDS += $(HIFIBERRY_UPDATER_INSTALL_FIRMWARE)
HIFIBERRY_UPDATER_INSTALL_TARGET_CMDS += $(HIFIBERRY_UPDATER_INSTALL_KERNEL)

$(eval $(generic-package))
