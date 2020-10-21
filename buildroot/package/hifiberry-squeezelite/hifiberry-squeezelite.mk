################################################################################
#
# hifiberry-squeezelite
#
################################################################################

HIFIBERRY_SQUEEZELITE_VERSION = 201358383f8e87b92d248c07e4a0eedaa7b1754d
HIFIBERRY_SQUEEZELITE_SITE = $(call github,ralph-irving,squeezelite,$(SQUEEZELITE_VERSION))
HIFIBERRY_SQUEEZELITE_LICENSE = GPL-3.0
HIFIBERRY_SQUEEZELITE_LICENSE_FILES = LICENSE.txt
HIFIBERRY_SQUEEZELITE_DEPENDENCIES = alsa-lib flac libmad libvorbis mpg123
HIFIBERRY_SQUEEZELITE_MAKE_OPTS = -DLINKALL

HIFIBERRY_SQUEEZELITE_DEPENDENCIES += faad2
HIFIBERRY_SQUEEZELITE_DEPENDENCIES += ffmpeg
HIFIBERRY_SQUEEZELITE_MAKE_OPTS += -DDSD

define HIFIBERRY_SQUEEZELITE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) \
		OPTS="$(SQUEEZELITE_MAKE_OPTS)" -C $(@D) all
endef

define HIFIBERRY_SQUEEZELITE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/squeezelite \
		$(TARGET_DIR)/usr/bin/squeezelite
	mkdir -p $(TARGET_DIR)/var/squeezelite
	echo "HiFiBerry" > $(TARGET_DIR)/var/squeezelite/squeezelite.name
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-squeezelite/squeezelite-start \
                $(TARGET_DIR)/bin/squeezelite-start
endef

define HIFIBERRY_SQUEEZELITE_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-squeezelite/squeezelite.service \
                $(TARGET_DIR)/usr/lib/systemd/system/squeezelite.service
	mkdir -p $(TARGET_DIR)/lib/systemd/system-preset
	echo "disable squeezelite.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-squeezelite.preset
endef

$(eval $(generic-package))
