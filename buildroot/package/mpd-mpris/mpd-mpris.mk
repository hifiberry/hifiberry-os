################################################################################
#
# mpd-mpris
#
################################################################################

MPD_MPRIS_VERSION = 0.2.2
MPD_MPRIS_SOURCE = v$(MPD_MPRIS_VERSION).tar.gz
MPD_MPRIS_SITE = https://github.com/natsukagami/mpd-mpris/archive

#MPD_MPRIS_VERSION = 6ef47aebacf119eb0b0bfb0a1dfdb4850e8d44b9
#MPD_MPRIS_SITE = $(call github,natsukagami,mpd-mpris,$(MPD_MPRIS_VERSION))



MPD_MPRIS_BUILD_TARGETS=./cmd/mpd-mpris/main.go
MPD_MPRIS_BIN_NAME=mpd-mpris

define MPD_MPRIS_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/mpd-mpris/mpd-mpris.service \
		$(TARGET_DIR)/usr/lib/systemd/system/mpd-mpris.service
endef

$(eval $(golang-package))
