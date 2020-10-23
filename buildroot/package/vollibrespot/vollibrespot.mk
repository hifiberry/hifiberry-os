################################################################################
#
# vollibrespot
#
################################################################################

VOLLIBRESPOT_VERSION = cd963998c50e0b97d68b1f28ba4bdf21ea652735
VOLLIBRESPOT_SITE = $(call github,ashthespy,Vollibrespot,$(VOLLIBRESPOT_VERSION))

VOLLIBRESPOT_LICENSE = MIT
VOLLIBRESPOT_LICENSE_FILES = LICENSE
VOLLIBRESPOT_INSTALL_TARGET = YES
VOLLIBRESPOT_INSTALL_STAGING = YES

VOLLIBRESPOT_DEPENDENCIES = host-rustc

VOLLIBRESPOT_CARGO_ENV = \
    PKG_CONFIG_ALLOW_CROSS=1 \
    CARGO_HOME=$(HOST_DIR)/share/cargo \
    RUST_TARGET_PATH=$(HOST_DIR)/etc/rustc \
    TARGET_CC=$(TARGET_CC) \
    CC=$(TARGET_CC)
    
VOLLIBRESPOT_CARGO_OPTS = \
    --target=${RUSTC_TARGET_NAME} \
    --manifest-path=$(@D)/Cargo.toml \
    --no-default-features

ifeq ($(BR2_ENABLE_DEBUG),y)
VOLLIBRESPOT_CARGO_MODE = debug 
else
VOLLIBRESPOT_CARGO_MODE = release
endif

VOLLIBRESPOT_CARGO_OPTS += --${VOLLIBRESPOT_CARGO_MODE} #--features ${VOLLIBRESPOT_CARGO_FEATURES}

define VOLLIBRESPOT_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(VOLLIBRESPOT_CARGO_ENV) \
            cargo build $(VOLLIBRESPOT_CARGO_OPTS)
endef

#target/armv7-unknown-linux-gnueabihf/release/librespot
define VOLLIBRESPOT_INSTALL_TARGET_CMDS
    $(INSTALL) -D \
            $(@D)/target/$(RUSTC_TARGET_NAME)/$(VOLLIBRESPOT_CARGO_MODE)/vollibrespot \
            $(TARGET_DIR)/usr/bin/vollibrespot
            
    $(TARGET_STRIP) --strip-all $(TARGET_DIR)/usr/bin/vollibrespot

    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/vollibrespot/vollibrespot.conf \
                $(TARGET_DIR)/etc/vollibrespot.conf
endef

define VOLLIBRESPOT_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/vollibrespot/vollibrespot.service \
                $(TARGET_DIR)/usr/lib/systemd/system/vollibrespot.service
endef

$(eval $(generic-package))

