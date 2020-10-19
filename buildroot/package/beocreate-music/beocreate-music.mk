################################################################################
#
# beocreate-music
#
################################################################################

BEOCREATE_MUSIC_VERSION = 19b6a47ea3a4cfee8af0adc2aecba088a26a75f5
BEOCREATE_MUSIC_SITE = $(call github,tuomashamalainen,beocreate-music,$(BEOCREATE_MUSIC_VERSION))

define BEOCREATE_MUSIC_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/music
	cp -rv $(@D)/music/* $(TARGET_DIR)/opt/beocreate/beo-extensions/music
endef

$(eval $(generic-package))
