################################################################################
#
# hifiberry-measurements
#
################################################################################

define HIFIBERRY_MEASUREMENTS_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/analyze \
           $(TARGET_DIR)/opt/hifiberry/bin/fft-analzye
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/audio-inputs \
           $(TARGET_DIR)/opt/hifiberry/bin/audio-inputs
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/record-sweep \
           $(TARGET_DIR)/opt/hifiberry/bin/record-sweep
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/room-measure \
           $(TARGET_DIR)/opt/hifiberry/bin/room-measure

endef

define HIFIBERRY_POSTGRES_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
