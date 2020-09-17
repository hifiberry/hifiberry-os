################################################################################
#
# hifiberry-upmpdcli
#
################################################################################

HIFIBERRY_UPMPDCLI_DEPENDENCIES = upmpdcli

define HIFIBERRY_UPMPDCLI_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/upmpdcli.conf \
            $(TARGET_DIR)/etc/upmpdcli.conf
    $(INSTALL) -D -m 644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/upmpdcli-user \
	    $(TARGET_DIR)/opt/hifiberry/bin/upmpdcli
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-upmpdcli/upmpdcli.service \
           $(TARGET_DIR)/usr/lib/systemd/system/upmpdcli.service
endef

$(eval $(generic-package))
