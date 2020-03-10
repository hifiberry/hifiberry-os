################################################################################
#
# webradio
#
################################################################################

WEBRADIO_VERSION = 83be60bcc4404cccf38e27b0747cfd50fd4a693e
WEBRADIO_SITE = $(call github,juangaimaro,radio,$(WEBRADIO_VERSION))

#WEBRADIO_VERSION = 38109377aec2bcd6f85671cc986c3a4ce45f5d80
#WEBRADIO_SITE = $(call github,hifiberry,radio,$(WEBRADIO_VERSION))

define WEBRADIO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/webradio/start-radio \
           $(TARGET_DIR)/opt/hifiberry/bin/start-radio
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
	cp -rv $(@D)/* $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
endef

$(eval $(generic-package))
