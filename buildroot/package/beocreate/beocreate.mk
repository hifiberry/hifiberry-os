################################################################################
#
# beocreate
#
################################################################################

#BEOCREATE_VERSION = 1185fec35a1dc50e1b2af31652f23507e6277a57
#BEOCREATE_SITE = $(call github,bang-olufsen,create,$(BEOCREATE_VERSION))

BEOCREATE_VERSION = 8a635fc9275ddfdcbc7b49ed92c307902a5a1217
BEOCREATE_SITE = $(call github,hifiberry,create,$(BEOCREATE_VERSION))

BEOCREATE_DEPENDENCIES += nodejs

define BEOCREATE_BUILD_CMDS
endef

define BEOCREATE_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/beocreate
	mkdir -p $(TARGET_DIR)/etc/beocreate
	mkdir -p $(TARGET_DIR)/etc/beocreate/beo-room-compensation
        cp -rv $(@D)/Beocreate2/* $(TARGET_DIR)/opt/beocreate
        rm -rf $(TARGET_DIR)/opt/beocreate/etc
	cp -rv $(@D)/beocreate_essentials $(TARGET_DIR)/opt/beocreate
	cp -rv $(@D)/Beocreate2/etc/* $(TARGET_DIR)/etc/beocreate
        # DSP Parameter Reader
        mkdir -p $(TARGET_DIR)/opt/beocreate/misc/dspparamreader
        cp -rv $(@D)/DSP\ Parameter\ Reader/* $(TARGET_DIR)/opt/beocreate/misc/dspparamreader
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/system.json \
                $(TARGET_DIR)/etc/beocreate/system.json
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/system.json \
                $(TARGET_DIR)/etc/beocreate/system.json.orig
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/sources.json \
                $(TARGET_DIR)/etc/beocreate/sources.json
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/sources.json \
                $(TARGET_DIR)/etc/beocreate/sources.json.orig
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/sound.json \
                $(TARGET_DIR)/etc/beocreate/sound.json
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/sound.json \
                $(TARGET_DIR)/etc/beocreate/sound.json.orig
	# Temporary fix
	#$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/sound-index.js.fixed \
	#	$(TARGET_DIR)/opt/beocreate/beo-extensions/sound/index.js
endef

define BEOCREATE_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/override.conf \
                $(TARGET_DIR)/etc/systemd/system/beocreate2.service.d/override.conf
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/beocreate/beocreate2.service \
                $(TARGET_DIR)/lib/systemd/system/beocreate2.service
endef

$(eval $(generic-package))
