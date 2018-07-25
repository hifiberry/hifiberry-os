################################################################################
#
# spotifyd
#
################################################################################

SPOTIFYD_VERSION = v0.2.2
SPOTIFYD_SITE = $(call github,Spotify,spotify,$(SPOTIFYD_VERSION))
SPOTIFYD_LICENSE = GPL-3.0
SPOTIFYD_LICENSE_FILES = LICENSE

SPOTIFYD_DEPENDENCIES = host-cargo

SPOTIFYD_CARGO_ENV = CARGO_HOME=$(HOST_DIR)/share/cargo
SPOTIFYD_CARGO_MODE = $(if $(BR2_ENABLE_DEBUG),debug,release)

SPOTIFYD_BIN_DIR = target/$(RUSTC_TARGET_NAME)/$(SPOTIFYD_CARGO_MODE)

SPOTIFYD_CARGO_OPTS = \
  --$(SPOTIFYD_CARGO_MODE) \
    --target=$(RUSTC_TARGET_NAME) \
    --manifest-path=$(@D)/Cargo.toml

define SPOTIFYD_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(SPOTIFYD_CARGO_ENV) \
          cargo build $(SPOTIFYD_CARGO_OPTS)
endef

define SPOTIFYD_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/$(SPOTIFYD_BIN_DIR)/foo \
           $(TARGET_DIR)/usr/bin/foo
endef

$(eval $(generic-package))
