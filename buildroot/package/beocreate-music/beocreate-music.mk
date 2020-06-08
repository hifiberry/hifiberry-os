################################################################################
#
# beocreate-music
#
################################################################################

BEOCREATE_MUSIC_VERSION = eb84798642e0362ff2c2741dc1447e8d8cd2c6fc
BEOCREATE_MUSIC_SITE = $(call github,tuomashamalainen,beocreate-music,$(BEOCREATE_MUSIC_VERSION))

define BEOCREATE_MUSIC_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/music
	cp -rv $(@D)/music/* $(TARGET_DIR)/opt/beocreate/beo-extensions/music
endef

$(eval $(generic-package))
