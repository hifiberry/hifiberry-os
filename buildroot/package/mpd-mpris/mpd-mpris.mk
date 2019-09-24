################################################################################
#
# mpd-mpris
#
################################################################################

MPD_MPRIS_VERSION = 0.2.2
MPD_MPRIS_SOURCE = v$(MPD_MPRIS_VERSION).tar.gz
MPD_MPRIS_SITE = https://github.com/natsukagami/mpd-mpris/archive

MPD_MPRIS_BUILD_TARGETS=./cmd/mpd-mpris/main.go
MPD_MPRIS_BIN_NAME=mpd-mpris

define MPD_MPRIS_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/mpd-mpris/mpd-mpris.service \
           $(TARGET_DIR)/usr/lib/systemd/system/mpd-mpris.service
    ln -fs ../../../../usr/lib/systemd/system/mpd-mpris.service \
           $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/mpd-mpris.service
endef

$(eval $(golang-package))
