################################################################################
#
# hattools
#
################################################################################

HATTOOLS_VERSION = 5f2058bf8eebf43dd19d7218f1e38d14a9835231
HATTOOLS_SITE = $(call github,raspberrypi,hats,$(HATTOOLS_VERSION))
HATTOOLS_STRIP_COMPONENTS=2

define HATTOOLS_BUILD_CMDS
     $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define HATTOOLS_INSTALL_TARGET_CMDS
     $(INSTALL) -D -m 0755 $(@D)/eepmake $(TARGET_DIR)/usr/bin/
     $(INSTALL) -D -m 0755 $(@D)/eepdump $(TARGET_DIR)/usr/bin/

     $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hattools/eeprom/hbflash.sh \
                $(TARGET_DIR)/opt/hifiberry/bin
     mkdir -p $(TARGET_DIR)/opt/hifiberry/eeprom/
     cp -r $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hattools/eeprom/*.eep \
	        $(TARGET_DIR)/opt/hifiberry/eeprom/
endef

$(eval $(generic-package))
