################################################################################
#
# extension-spotify
#
################################################################################

EXTENSION_SPOTIFY_DEPENDENCIES = extensions

define EXTENSION_SPOTIFY_INSTALL_TARGET_CMDS
    cat $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/extension_spotify/extensions.conf \
        >> $(TARGET_DIR)/etc/extensions.conf
endef

$(eval $(generic-package))
