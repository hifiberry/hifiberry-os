################################################################################
#
# mpris-proxy
#
################################################################################


define MPRIS_PROXY_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/mpris-proxy/dbus.conf \
           $(TARGET_DIR)/etc/dbus-1/system.d/mpris-proxy.conf
endef

define SPOTIFYD_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/mpris-proxy/mpris-proxy.service \
           $(TARGET_DIR)/usr/lib/systemd/system/mpris-proxy.service
    ln -fs ../../../usr/lib/systemd/system/mpris-proxy.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/mpris-proxy.service
endef

$(eval $(generic-package))
