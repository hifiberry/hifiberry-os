################################################################################
#
# hifiberry-upmpdcli
#
################################################################################

HIFIBERRY_UPMPDCLI_DEPENDENCIES = upmpdcli

define HIFIBERRY_UPMPDCLI_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/upmpdcli.conf \
            $(TARGET_DIR)/etc/upmpdcli.conf
    $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/forward.html \
            $(TARGET_DIR)/etc/upmpdcli.html
    $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/description.xml \
	    $(TARGET_DIR)/usr/share/upmpdcli/description.xml
    $(INSTALL) -D -m 755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/upmpdcli-user \
	    $(TARGET_DIR)/opt/hifiberry/bin/upmpdcli-user
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/upmpdcli.service \
           $(TARGET_DIR)/usr/lib/systemd/system/upmpdcli.service
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/openhome-room \
           $(TARGET_DIR)/opt/hifiberry/bin/openhome-room

    # Not yet ready for production
    echo "disable upmpdcli.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-upmpdcli.preset 
endef

$(eval $(generic-package))
