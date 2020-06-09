################################################################################
#
# beocreate-music
#
################################################################################

BEOCREATE_MUSIC_VERSION = e3fcc4dc191ba2bd54b816148a7478f772ba3c13
BEOCREATE_MUSIC_SITE = $(call github,tuomashamalainen,beocreate-music,$(BEOCREATE_MUSIC_VERSION))

define BEOCREATE_MUSIC_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/music
	cp -rv $(@D)/music/* $(TARGET_DIR)/opt/beocreate/beo-extensions/music
endef

$(eval $(generic-package))
