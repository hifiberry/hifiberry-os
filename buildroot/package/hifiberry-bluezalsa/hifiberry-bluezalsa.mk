################################################################################
#
# hifiberry-bluezalsa
#
################################################################################

HIFIBERRY_BLUEZALSA_VERSION = 1.4.0
HIFIBERRY_BLUEZALSA_SITE = $(call github,Arkq,bluez-alsa,v$(HIFIBERRY_BLUEZALSA_VERSION))
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
	--with-alsaconfdir=/usr/share/alsa

ifeq ($(BR2_PACKAGE_FDK_AAC),y)
HIFIBERRY_BLUEZALSA_DEPENDENCIES += fdk-aac
HIFIBERRY_BLUEZALSA_CONF_OPTS += --enable-aac
else
HIFIBERRY_BLUEZALSA_CONF_OPTS += --disable-aac
endif

#HIFIBERRY_BLUEZALSA_DEPENDENCIES += libbsd ncurses
#HIFIBERRY_BLUEZALSA_CONF_OPTS += --enable-hcitop

#HIFIBERRY_BLUEZALSA_DEPENDENCIES += readline
#HIFIBERRY_BLUEZALSA_CONF_OPTS += --enable-rfcomm

$(eval $(autotools-package))
