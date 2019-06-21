################################################################################
#
# hifiberry-mpd
#
################################################################################

define HIFIBERRY_MPD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/S99mpd \
                $(TARGET_DIR)/etc/init.d/S99mpd
	mkdir -p $(TARGET_DIR)/var/mpd
	mkdir -p $(TARGET_DIR)/library
	mkdir -p $(TARGET_DIR)/library/music
	mkdir -p $(TARGET_DIR)/library/playlists
	wget http://www.byte.fm/stream/bytefm.m3u
	mv bytefm.m3u $(TARGET_DIR)/library/playlists
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/mpd.conf \
		$(TARGET_DIR)/etc/mpd.conf
endef

$(eval $(generic-package))
