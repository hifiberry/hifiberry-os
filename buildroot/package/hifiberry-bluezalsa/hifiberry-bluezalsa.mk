################################################################################
#
# hifiberry-bluezalsa
#
################################################################################

HIFIBERRY_BLUEZALSA_VERSION = 2.1.0
HIFIBERRY_BLUEZALSA_SITE = $(call github,Arkq,bluez-alsa,v$(HIFIBERRY_BLUEZALSA_VERSION))
HIFIBERRY_BLUEZALSA_VERSION = 01fc155f2200d457f19c11692994e58e606b6433
#HIFIBERRY_BLUEZALSA_VERSION = c9021d932ae9464b6cdc4ca5ac240a6b8ada6e36
HIFIBERRY_BLUEZALSA_SITE = $(call github,joerg-krause,bluez-alsa,$(HIFIBERRY_BLUEZALSA_VERSION))
HIFIBERRY_BLUEZALSA_LICENSE = MIT
HIFIBERRY_BLUEZALSA_LICENSE_FILES = LICENSE
HIFIBERRY_BLUEZALSA_DEPENDENCIES = alsa-lib bluez5_utils libglib2 sbc host-pkgconf

# git repo, no configure
HIFIBERRY_BLUEZALSA_AUTORECONF = YES

# Autoreconf requires an existing m4 directory
define HIFIBERRY_BLUEZALSA_MKDIR_M4
	mkdir -p $(@D)/m4
endef
HIFIBERRY_BLUEZALSA_POST_PATCH_HOOKS += HIFIBERRY_BLUEZALSA_MKDIR_M4

HIFIBERRY_BLUEZALSA_CONF_OPTS = \
	--enable-aplay \
	--disable-debug-time \
	--with-alsaplugindir=/usr/lib/alsa-lib \
	--with-alsaconfdir=/usr/share/alsa \
	--disable-payloadcheck

# Enable AAC
HIFIBERRY_BLUEZALSA_DEPENDENCIES += fdk-aac
HIFIBERRY_BLUEZALSA_CONF_OPTS += --enable-aac

#HIFIBERRY_BLUEZALSA_DEPENDENCIES += libbsd ncurses
#HIFIBERRY_BLUEZALSA_CONF_OPTS += --enable-hcitop

HIFIBERRY_BLUEZALSA_DEPENDENCIES += readline
HIFIBERRY_BLUEZALSA_CONF_OPTS += --enable-rfcomm

define HIFIBERRY_BLUEZALSA_INSTALL_INIT_SYSTEMD
	mkdir -p $(TARGET_DIR)/opt/btspeaker
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-bluezalsa/bluealsa.service \
                $(TARGET_DIR)/lib/systemd/system/bluealsa.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-bluezalsa/bluealsa-aplay.service\
                $(TARGET_DIR)/usr/lib/systemd/system/bluealsa-aplay.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-bluezalsa/bluealsa-aplay-start \
                $(TARGET_DIR)/opt/btspeaker/bluealsa-aplay-start
endef


$(eval $(autotools-package))
