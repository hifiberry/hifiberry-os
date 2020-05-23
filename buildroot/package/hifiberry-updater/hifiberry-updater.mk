################################################################################
#
# hifiberry-updater
#
################################################################################

define HIFIBERRY_UPDATER_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/var/spool/cron/crontabs
	mkdir -p $(TARGET_DIR)/etc/systemd/system/timers.target.wants
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
        [ -d $(TARGET_DIR)/etc/systemd/system/timers.target.wants ] || mkdir $(TARGET_DIR)/etc/systemd/system/timers.target.wants
        ln -fs ../../../../usr/lib/systemd/system/updater.timer \
             $(TARGET_DIR)/etc/systemd/system/timers.target.wants/updater.timer
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
define RPI_INSTALL_FIRMWARE
        echo "Pi 4"
        $(INSTALL) -D -m 0644 $(@D)/boot/start4$(BR2_PACKAGE_RPI_FIRMWARE_BOOT).elf $(TARGET_DIR)/usr/lib/firmware/rpi/start4.elf
        $(INSTALL) -D -m 0644 $(@D)/boot/fixup4$(BR2_PACKAGE_RPI_FIRMWARE_BOOT).dat $(TARGET_DIR)/usr/lib/firmware/rpi/fixup4.dat

endef
else
define RPI_INSTALL_FIRMWARE
        echo "Pi < 4"
        $(INSTALL) -D -m 0644 $(@D)/boot/start$(BR2_PACKAGE_RPI_FIRMWARE_BOOT).elf $(TARGET_DIR)/usr/lib/firmware/rpi/start.elf
        $(INSTALL) -D -m 0644 $(@D)/boot/fixup$(BR2_PACKAGE_RPI_FIRMWARE_BOOT).dat $(TARGET_DIR)/usr/lib/firmware/rpi/fixup.dat

endef
endif

define RPI_INSTALL_OVERLAYS
        echo "Installing overlays"
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/rpi/overlays
        for ovldtb in $(@D)/boot/overlays/*.dtbo; do \
                $(INSTALL) -D -m 0644 $${ovldtb} $(TARGET_DIR)/usr/lib/firmware/rpi/overlays/$${ovldtb##*/} || exit 1; \
        done
endef

RPI_FIRMWARE_INSTALL_TARGET_CMDS += $(RPI_INSTALL_FIRMWARE)
RPI_FIRMWARE_INSTALL_TARGET_CMDS += $(RPI_INSTALL_OVERLAYS)

$(eval $(generic-package))
