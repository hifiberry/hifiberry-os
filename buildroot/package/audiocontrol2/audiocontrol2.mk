################################################################################
#
# audiocontrol2
#
################################################################################

AUDIOCONTROL2_VERSION = fdc45b1665060f87f5cb75a1ad857b01a18e0994
AUDIOCONTROL2_SITE = $(call github,hifiberry,audiocontrol2,$(AUDIOCONTROL2_VERSION))

AUDIOCONTROL2_DEPENDENCIES = python3

define AUDIOCONTROL2_BUILD_CMDS
endef

define AUDIOCONTROL2_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/audiocontrol2
        cp -rv $(@D)/* $(TARGET_DIR)/opt/audiocontrol2
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/audiocontrol2.conf \
		$(TARGET_DIR)/etc
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/audiocontrol2.conf \
                $(TARGET_DIR)/etc/audiocontrol2.conf.orig
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/privacy.html \
		$(TARGET_DIR)/opt/audiocontrol2/privacy.html
	$(INSTALL)  -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/git-update-audiocontrol \
		$(TARGET_DIR)/opt/hifiberry/bin/git-update-audiocontrol
endef

define AUDIOCONTROL2_INSTALL_INIT_SYSTEMD
    	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/override.conf \
                $(TARGET_DIR)/etc/systemd/system/audiocontrol2.service.d/override.conf
    	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/audiocontrol2.service \
           	$(TARGET_DIR)/usr/lib/systemd/system/audiocontrol2.service
endef

$(eval $(generic-package))
