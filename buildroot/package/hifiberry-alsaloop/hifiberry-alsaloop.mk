################################################################################
#
# hifiberry-alsaloop
#
################################################################################

HIFIBERRY_ALSALOOP_VERSION = c4674d7609bf96d34b206ca07d87e6e239d6df95
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
