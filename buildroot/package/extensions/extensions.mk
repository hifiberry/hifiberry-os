################################################################################
#
# extensions
#
################################################################################

EXTENSIONS_VERSION = 0d5b597fa0c5c0d402dc6e75df07c90f3ebab5ca
EXTENSIONS_SITE = $(call github,hifiberry,hifiberryos-extensions,$(EXTENSIONS_VERSION))

EXTENSIONS_DEPENDENCIES = python3

define EXTENSIONS_BUILD_CMDS
endef

define EXTENSIONS_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/opt/extensions
    cp -rv $(@D)/* $(TARGET_DIR)/opt/extensions
    chmod +x $(TARGET_DIR)/opt/extensions/extensions.py
    -rm $(TARGET_DIR)/opt/hifiberry/bin/extensions
    ln -s ../../extensions/extensions.py $(TARGET_DIR)/opt/hifiberry/bin/extensions
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/extensions/extensions.conf \
        $(TARGET_DIR)/etc/extensions.conf
endef

define EXTENSIONS_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/extensions/extensions.service \
        $(TARGET_DIR)/lib/systemd/system/extensions.service
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/extensions/extensions-install.service \
        $(TARGET_DIR)/lib/systemd/system/extensions-install.service
endef


$(eval $(generic-package))
