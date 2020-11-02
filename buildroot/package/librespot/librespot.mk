################################################################################
#
# librespot
#
################################################################################

LIBRESPOT_VERSION = 1b1c22b6bc1e330fef731f5b3bc3b130d52a5bff
LIBRESPOT_SITE = $(call github,librespot-org,librespot,$(LIBRESPOT_VERSION))

LIBRESPOT_LICENSE = MIT
LIBRESPOT_LICENSE_FILES = LICENSE
LIBRESPOT_INSTALL_TARGET = YES
LIBRESPOT_INSTALL_STAGING = YES

LIBRESPOT_DEPENDENCIES = host-rustc

LIBRESPOT_CARGO_ENV = \
    PKG_CONFIG_ALLOW_CROSS=1 \
    CARGO_HOME=$(HOST_DIR)/share/cargo \
    RUST_TARGET_PATH=$(HOST_DIR)/etc/rustc \
    TARGET_CC=$(TARGET_CC) \
    CC=$(TARGET_CC)
    
LIBRESPOT_CARGO_OPTS = \
    --target=${RUSTC_TARGET_NAME} \
    --manifest-path=$(@D)/Cargo.toml \
    --no-default-features

ifeq ($(BR2_ENABLE_DEBUG),y)
LIBRESPOT_CARGO_MODE = debug 
else
LIBRESPOT_CARGO_MODE = release
endif

ifeq ($(BR2_PACKAGE_ALSA_LIB),y)
LIBRESPOT_CARGO_FEATURES += alsa-backend
endif

ifeq ($(BR2_PACKAGE_PORTAUDIO),y)
LIBRESPOT_CARGO_FEATURES += portaudio-backend
endif

LIBRESPOT_CARGO_OPTS += --${LIBRESPOT_CARGO_MODE} --features ${LIBRESPOT_CARGO_FEATURES}

define LIBRESPOT_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(LIBRESPOT_CARGO_ENV) \
            cargo build $(LIBRESPOT_CARGO_OPTS)
endef

#target/armv7-unknown-linux-gnueabihf/release/librespot
define LIBRESPOT_INSTALL_TARGET_CMDS
    $(INSTALL) -D \
            $(@D)/target/$(RUSTC_TARGET_NAME)/$(LIBRESPOT_CARGO_MODE)/librespot \
            $(TARGET_DIR)/usr/bin/librespot
            
    $(TARGET_STRIP) --strip-all $(TARGET_DIR)/usr/bin/librespot         
endef

$(eval $(generic-package))

