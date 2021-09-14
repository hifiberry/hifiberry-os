################################################################################
#
# hifiberry-bluezalsa
#
################################################################################

#HIFIBERRY_BLUEZALSA_VERSION = 2.1.0
HIFIBERRY_BLUEZALSA_SITE = $(call github,Arkq,bluez-alsa,$(HIFIBERRY_BLUEZALSA_VERSION))
HIFIBERRY_BLUEZALSA_VERSION = aac8742a9e7dd12a1fead9cbce7d2dc8b961999c
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
