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
	echo "Installing kernel"
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/linux-custom/arch/arm/boot/zImage $(TARGET_DIR)/usr/lib/firmware/rpi
	echo "Installing updater"
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/../scripts/updater.sh $(TARGET_DIR)/tmp/updater.sh
	echo "F2FS supported"
	touch $(TARGET_DIR)/etc/f2fs 

endef

define HIFIBERRY_UPDATER_INSTALL_INIT_SYSTEMD
endef

### 
### Add more functions to RPI firmware
###
ifeq ($(BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI4),y)
define HIFIBERRY_UPDATER_INSTALL_FIRMWARE
        echo "HiFiBerry updater: adding Pi4 firmware files to /usr/lib/firmware/rpi"
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot/start4.elf $(TARGET_DIR)/usr/lib/firmware/rpi/start.elf
        $(INSTALL) -D -m 0644 $(BUILD_DIR)/rpi-firmware-$(RPI_FIRMWARE_VERSION)/boot/fixup4.dat $(TARGET_DIR)/usr/lib/firmware/rpi/fixup.dat

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
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/rpi/overlays
        for ovldtb in $(@D)/boot/overlays/*.dtbo; do \
                $(INSTALL) -D -m 0644 $${ovldtb} $(TARGET_DIR)/usr/lib/firmware/rpi/overlays/$${ovldtb##*/} || exit 1; \
        done
endef

HIFIBERRY_UPDATER_INSTALL_TARGET_CMDS += $(HIFIBERRY_UPDATER_INSTALL_FIRMWARE)

#ifneq ($(BR2_PACKAGE_COPY_ALL_OVERLAYS),y)
#HIFIBERRY_UPDATER_INSTALL_TARGET_CMDS += $(HIFIBERRY_UPDATER_INSTALL_ALL_OVERLAYS)
#endif

$(eval $(generic-package))
