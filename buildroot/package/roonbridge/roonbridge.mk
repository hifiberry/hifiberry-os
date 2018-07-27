################################################################################
#
# roonbridge
#
################################################################################

ROONBRIDGE_SOURCE = RoonBridge_linuxarmv7hf.tar.bz2
ROONBRIDGE_SITE = http://download.roonlabs.com/builds

ROONBRIDGE_CHECK_BIN_ARCH_EXCLUSIONS = \
	/opt/roon/RoonMono/lib/libmono-btls-shared.so \
	/opt/roon/RoonMono/lib/libmono-btls-shared.so

define ROONBRIDGE_BUILD_CMDS
    echo "No build needed"
endef

define ROONBRIDGE_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/opt/roon
    mkdir -p $(TARGET_DIR)/usr/share
    cp -rv $(@D)/Bridge $(TARGET_DIR)/opt/roon
    cp -rv $(@D)/RoonMono $(TARGET_DIR)/usr/share
endef

define ROONBRIDGE_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/roonbridge/S99roonbridge \
                $(TARGET_DIR)/etc/init.d/S99roonbridge
endef

define DSPTOOLKIT_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/roonbridge/roonbridge.service \
                $(TARGET_DIR)/lib/systemd/system/roonbridge.service
endef

$(eval $(generic-package))
