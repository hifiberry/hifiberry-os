################################################################################
#
# hifiberry-automount
#
################################################################################

define HIFIBERRY_AUTOMOUNT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/mount-usb.sh \
           $(TARGET_DIR)/opt/hifiberry/bin/mount-usb.sh
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/usbmount@.service \
           $(TARGET_DIR)/etc/systemd/system/usbmount@.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/99-usbmount.rules \
           $(TARGET_DIR)/etc/udev/rules.d/99-usbmount.rules

endef

$(eval $(generic-package))
