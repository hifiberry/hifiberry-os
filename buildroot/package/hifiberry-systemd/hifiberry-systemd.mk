################################################################################
#
# hifiberry-systemd
#
################################################################################

define HIFIBERRY_SYSTEMD_INSTALL_TARGET_CMDS
 	echo "Speed up network-online"
	sed -i "s/ExecStart.*/ExecStart=\/usr\/lib\/systemd\/systemd-networkd-wait-online\ --timeout=20 --any/" \
		$(TARGET_DIR)/usr/lib/systemd/system/systemd-networkd-wait-online.service
	echo "Adding ntp.org fix"
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-systemd/fix-ntp.service \
                $(TARGET_DIR)/lib/systemd/system/fix-ntp.service
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-systemd/fix-ntp.sh \
                $(TARGET_DIR)/opt/hifiberry/bin/fix-ntp.sh
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-systemd/autostart.service \
                $(TARGET_DIR)/lib/systemd/system/autostart.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-systemd/autostart.sh \
                $(TARGET_DIR)/opt/hifiberry/bin/autostart.sh
endef

$(eval $(generic-package))
