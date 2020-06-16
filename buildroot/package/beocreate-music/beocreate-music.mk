################################################################################
#
# beocreate-music
#
################################################################################

BEOCREATE_MUSIC_VERSION = 0510324112c477bcc349ab298d3fb2e9bb65ceae
BEOCREATE_MUSIC_SITE = $(call github,tuomashamalainen,beocreate-music,$(BEOCREATE_MUSIC_VERSION))

define BEOCREATE_MUSIC_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/music
	cp -rv $(@D)/music/* $(TARGET_DIR)/opt/beocreate/beo-extensions/music
endef

$(eval $(generic-package))
