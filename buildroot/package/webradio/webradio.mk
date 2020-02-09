################################################################################
#
# webradio
#
################################################################################

WEBRADIO=https://github.com/juangaimaro/radio

WEBRADIO_VERSION = 60810e1a1f787975235c0042d2d05c06666aa978
WEBRADIO_SITE = $(call github,juangaimaro,radio,$(WEBRADIO_VERSION))

define WEBRADIO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/webradio/start-radio \
           $(TARGET_DIR)/opt/hifiberry/bin/start-radio
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
	cp -rv $(@D)/* $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
endef

$(eval $(generic-package))
