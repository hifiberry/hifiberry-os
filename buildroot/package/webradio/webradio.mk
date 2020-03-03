################################################################################
#
# webradio
#
################################################################################

WEBRADIO_VERSION = c5de983f41577007c6eef8501494d6a9cbf30ad6
WEBRADIO_SITE = $(call github,juangaimaro,radio,$(WEBRADIO_VERSION))

WEBRADIO_VERSION = 38109377aec2bcd6f85671cc986c3a4ce45f5d80
WEBRADIO_SITE = $(call github,hifiberry,radio,$(WEBRADIO_VERSION))

define WEBRADIO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/webradio/start-radio \
           $(TARGET_DIR)/opt/hifiberry/bin/start-radio
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
	cp -rv $(@D)/* $(TARGET_DIR)/opt/beocreate/beo-extensions/radio
endef

$(eval $(generic-package))
