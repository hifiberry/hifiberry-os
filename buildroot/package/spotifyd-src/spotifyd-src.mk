################################################################################
#
# spotifyd-src
#
################################################################################

SPOTIFYD_SRC_VERSION = master
SPOTIFYD_SRC_SITE = $(call github,Spotifyd,spotifyd,$(SPOTIFYD_SRC_VERSION))
SPOTIFYD_SRC_LICENSE = GPL-3.0
SPOTIFYD_SRC_LICENSE_FILES = LICENSE

SPOTIFYD_SRC_DEPENDENCIES = host-cargo

SPOTIFYD_SRC_CARGO_ENV = CARGO_HOME=$(HOST_DIR)/share/cargo \
 CC=$(HOST_DIR)/bin/arm-buildroot-linux-gnueabihf-gcc \
 PKG_CONFIG_ALLOW_CROSS=1 \
 OPENSSL_LIB_DIR=$(HOST_DIR)/lib \
 OPENSSL_INCLUDE_DIR=$(HOST_DIR)/include 
SPOTIFYD_SRC_CARGO_MODE = $(if $(BR2_ENABLE_DEBUG),debug,release)

SPOTIFYD_SRC_BIN_DIR = target/$(RUSTC_TARGET_NAME)/release

SPOTIFYD_SRC_CARGO_OPTS = \
  --$(SPOTIFYD_SRC_CARGO_MODE) \
    --target=$(RUSTC_TARGET_NAME) \
    --manifest-path=$(@D)/Cargo.toml

define SPOTIFYD_SRC_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(SPOTIFYD_SRC_CARGO_ENV) \
	  rustc -V
    $(TARGET_MAKE_ENV) $(SPOTIFYD_SRC_CARGO_ENV) \
          cargo build $(SPOTIFYD_SRC_CARGO_OPTS)
endef


define SPOTIFYD_SRC_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/$(SPOTIFYD_BIN_DIR)/spotifyd \
           $(TARGET_DIR)/usr/bin/spotifyd
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/spotifyd-src/spotifyd.conf \
           $(TARGET_DIR)/etc/spotifyd.conf
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/spotifyd-src/dbus.conf \
           $(TARGET_DIR)/etc/dbus-1/system.d/spotify.conf

endef

define SPOTIFYD_SRC_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/spotifyd-src/spotify.service \
           $(TARGET_DIR)/usr/lib/systemd/system/spotify.service
    ln -fs ../../../../usr/lib/systemd/system/spotify.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/spotify.service
endef


$(eval $(generic-package))
