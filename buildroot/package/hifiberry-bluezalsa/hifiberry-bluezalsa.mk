################################################################################
#
# hifiberry-bluezalsa
#
################################################################################

HIFIBERRY_BLUEZALSA_VERSION = v3.1.0
HIFIBERRY_BLUEZALSA_SITE = $(call github,Arkq,bluez-alsa,$(HIFIBERRY_BLUEZALSA_VERSION))
#HIFIBERRY_BLUEZALSA_VERSION = 1bd6d0439916d80636d616617297bdd75e3e0512
HIFIBERRY_BLUEZALSA_VERSION = 6509c47c27219a08a64373239469e6f7a5549303
#HIFIBERRY_BLUEZALSA_VERSION = ec8a5138c46cd37290aaeaa1f79de33e996cf601
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
	--disable-payloadcheck \
	--disable-msbc \
	--enable-aac \
	--enable-mp3lame \
	--enable-openaptx \

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
