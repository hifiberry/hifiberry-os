################################################################################
#
# hifiberry-mpd-cd-autoplay
#
################################################################################

HIFIBERRY_MPD_CD_AUTOPLAY_VERSION = 0.0.1
HIFIBERRY_MPD_CD_AUTOPLAY_LICENSE = GPL-3.0+
HIFIBERRY_MPD_CD_AUTOPLAY_LICENSE_FILES = COPYING
HIFIBERRY_MPD_CD_AUTOPLAY_INSTALL_TARGET = YES
HIFIBERRY_MPD_CD_AUTOPLAY_SOURCE=

define HIFIBERRY_MPD_CD_AUTOPLAY_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd-cd-autoplay/80-mpd-cd-autoplay.rules \
                $(TARGET_DIR)/etc/udev/rules.d/80-mpd-cd-autoplay.rules
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd-cd-autoplay/mpd-cd-autoplay.sh \
                $(TARGET_DIR)/usr/bin/mpd-cd-autoplay.sh
endef

define HIFIBERRY_MPD_CD_AUTOPLAY_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd-cd-autoplay/mpd-cd-autoplay.service \
                $(TARGET_DIR)/usr/lib/systemd/system/mpd-cd-autoplay.service
endef

$(eval $(generic-package))
