################################################################################
#
# hifiberry-shairport
#
################################################################################

HIFIBERRY_SHAIRPORT_VERSION = 90c03bf0533ca10776db32c5206f605a3460c6d8
HIFIBERRY_SHAIRPORT_SITE = $(call github,mikebrady,shairport-sync,$(HIFIBERRY_SHAIRPORT_VERSION))

HIFIBERRY_SHAIRPORT_LICENSE = MIT, BSD-3-Clause
HIFIBERRY_SHAIRPORT_LICENSE_FILES = LICENSES
HIFIBERRY_SHAIRPORT_DEPENDENCIES = alsa-lib libconfig libdaemon popt host-pkgconf avahi

# git clone, no configure
HIFIBERRY_SHAIRPORT_AUTORECONF = YES

HIFIBERRY_SHAIRPORT_CONF_OPTS = --with-alsa \
        --with-metadata \
        --with-pipe \
        --with-stdout \
        --with-avahi \
        --with-mpris-interface \
        --with-mpris-test-client

HIFIBERRY_SHAIRPORT_CONF_ENV += LIBS="$(HIFIBERRY_SHAIRPORT_CONF_LIBS)"

# OpenSSL or mbedTLS
ifeq ($(BR2_PACKAGE_OPENSSL),y)
HIFIBERRY_SHAIRPORT_DEPENDENCIES += openssl
HIFIBERRY_SHAIRPORT_CONF_OPTS += --with-ssl=openssl
else
HIFIBERRY_SHAIRPORT_DEPENDENCIES += mbedtls
HIFIBERRY_SHAIRPORT_CONF_OPTS += --with-ssl=mbedtls
HIFIBERRY_SHAIRPORT_CONF_LIBS += -lmbedx509 -lmbedcrypto
ifeq ($(BR2_PACKAGE_MBEDTLS_COMPRESSION),y)
HIFIBERRY_SHAIRPORT_CONF_LIBS += -lz
endif
endif

ifeq ($(BR2_PACKAGE_HIFIBERRY_SHAIRPORT_LIBSOXR),y)
HIFIBERRY_SHAIRPORT_DEPENDENCIES += libsoxr
HIFIBERRY_SHAIRPORT_CONF_OPTS += --with-soxr
endif

ifeq ($(BR2_PACKAGE_HIFIBERRY_SHAIRPORT_AIRPLAY2),y)
HIFIBERRY_SHAIRPORT_DEPENDENCIES += libplist nqptp
HIFIBERRY_SHAIRPORT_CONF_OPTS += --with-airplay-2
endif

define HIFIBERRY_SHAIRPORT_INSTALL_TARGET_CMDS
        $(INSTALL) -D -m 0755 $(@D)/shairport-sync \
                $(TARGET_DIR)/usr/bin/shairport-sync
        $(INSTALL) -D -m 0755 $(@D)/shairport-sync-mpris-test-client \
                $(TARGET_DIR)/usr/bin/shairport-sync-mpris-test-client
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-shairport/shairport-sync.conf \
                $(TARGET_DIR)/etc/shairport-sync.conf
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-shairport/dbus.conf \
                $(TARGET_DIR)/etc/dbus-1/system.d/shairport-sync.conf
endef

define HIFIBERRY_SHAIRPORT_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 package/shairport-sync/S99shairport-sync \
                $(TARGET_DIR)/etc/init.d/S99shairport-sync
endef

define HIFIBERRY_SHAIRPORT_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-shairport/shairport-sync.service \
                $(TARGET_DIR)/usr/lib/systemd/system/shairport-sync.service
endef

# This is a hack as shairport-sync is looking for nqptp libraries in ../nqptp
define HIFIBERRY_SHAIRPORT_PROVIDE_NQPTP
	echo "Creating nqptp symlink"
        -rm $(BUILD_DIR)/nqptp
	ln -s $(BUILD_DIR)/nqptp-* $(BUILD_DIR)/nqptp
endef

HIFIBERRY_SHAIRPORT_PRE_BUILD_HOOKS += HIFIBERRY_SHAIRPORT_PROVIDE_NQPTP

$(eval $(autotools-package))
