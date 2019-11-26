################################################################################
#
# hifiberry-mpd
#
################################################################################

define HIFIBERRY_MPD_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/library
	mkdir -p $(TARGET_DIR)/library/music
	mkdir -p $(TARGET_DIR)/library/playlists
        mkdir -p $(TARGET_DIR)/var/lib/mpd
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/mpd.conf \
		$(TARGET_DIR)/etc/mpd.conf
        # Install some sample web radio files
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/radio/*.m3u \
                $(TARGET_DIR)/library/playlists/
endef

define HIFIBERRY_MPD_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/mpd.service \
                $(TARGET_DIR)/usr/lib/systemd/system/mpd.service
        ln -fs ../../../../usr/lib/systemd/system/shairport-sync.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/mpd.service
endef



$(eval $(generic-package))
