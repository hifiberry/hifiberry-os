################################################################################
#
# audiocontrol2
#
################################################################################

AUDIOCONTROL2_VERSION = 625f7fd826911657337398d4b09da4c3e14afb09
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
endef

define AUDIOCONTROL2_INSTALL_INIT_SYSTEMD
    	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/override.conf \
                $(TARGET_DIR)/etc/systemd/system/audiocontrol2.service.d/override.conf
    	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol2/audiocontrol2.service \
           	$(TARGET_DIR)/usr/lib/systemd/system/audiocontrol2.service
endef

$(eval $(generic-package))
