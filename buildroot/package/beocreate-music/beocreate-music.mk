################################################################################
#
# beocreate-music
#
################################################################################

BEOCREATE_MUSIC_VERSION = 7f5bd3bcd83fb7d718509b8197f690aae13963f2
BEOCREATE_MUSIC_SITE = $(call github,tuomashamalainen,beocreate-music,$(BEOCREATE_MUSIC_VERSION))

define BEOCREATE_MUSIC_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/music
	cp -rv $(@D)/music/* $(TARGET_DIR)/opt/beocreate/beo-extensions/music
endef

$(eval $(generic-package))
