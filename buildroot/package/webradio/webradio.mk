################################################################################
#
# webradio
#
################################################################################

WEBRADIO=https://github.com/juangaimaro/radio

WEBRADIO_VERSION =  d38cdafe83829262c2bd52db31e3722a4689bf4d
WEBRADIO_SITE = $(call github,juangaimaro,radio,$(WEBRADIO_VERSION))

define WEBRADIO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/webradio/start-radio \
           $(TARGET_DIR)/opt/hifiberry/bin/start-radio
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
	cp -rv $(@D)/* $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
endef

$(eval $(generic-package))
