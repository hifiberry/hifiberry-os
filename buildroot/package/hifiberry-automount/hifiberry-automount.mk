################################################################################
#
# hifiberry-automount
#
################################################################################

HIFIBERRY_AUTOMOUNT_DEPENDENCIES = systemd

define HIFIBERRY_AUTOMOUNT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/mount-usb.sh \
           $(TARGET_DIR)/opt/hifiberry/bin/mount-usb.sh
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/usbmount@.service \
           $(TARGET_DIR)/etc/systemd/system/usbmount@.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/99-usbmount.rules \
           $(TARGET_DIR)/etc/udev/rules.d/99-usbmount.rules
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/mount-smb.sh \
                $(TARGET_DIR)/opt/hifiberry/bin/mount-smb.sh
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/mount-all.sh \
                $(TARGET_DIR)/opt/hifiberry/bin/mount-all.sh
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/list-smb-servers \
		$(TARGET_DIR)/opt/hifiberry/bin/list-smb-servers
	touch $(TARGET_DIR)/etc/smbmounts.conf
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/mount-data.sh \
		$(TARGET_DIR)/opt/hifiberry/bin/mount-data.sh
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/mount-data.service \
		$(TARGET_DIR)/etc/systemd/system/mount-data.service
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-automount/list-usb-storage \
		$(TARGET_DIR)/opt/hifiberry/bin/list-usb-storage
endef

$(eval $(generic-package))
