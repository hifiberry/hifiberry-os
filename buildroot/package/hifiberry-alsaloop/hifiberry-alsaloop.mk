################################################################################
#
# hifiberry-alsaloop
#
################################################################################

HIFIBERRY_ALSALOOP_VERSION = 1bacf8e37b91bd2ae6c72fa6b34a4343dec6f43d
HIFIBERRY_ALSALOOP_SITE = $(call github,hifiberry,alsaloop,$(HIFIBERRY_ALSALOOP_VERSION))

define HIFIBERRY_ALSALOOP_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/alsaloop
	cp -rv $(@D)/* $(TARGET_DIR)/opt/alsaloop
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-alsaloop/dbus.conf \
			$(TARGET_DIR)/etc/dbus-1/system.d/alsaloop.conf
endef


define HIFIBERRY_ALSALOOP_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-alsaloop/alsaloop.service \
                $(TARGET_DIR)/usr/lib/systemd/system/alsaloop.service
	mkdir -p $(TARGET_DIR)/lib/systemd/system-preset
	echo "disable alsaloop.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-alsaloop.preset
endef

$(eval $(generic-package))
