################################################################################
#
# hifiberry-measurements
#
################################################################################

define HIFIBERRY_MEASUREMENTS_BUILD_CMDS
    cd $(@D); \
      pwd; \
      cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/analyze/* .; \
      $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) LDFLAGS=-lm CFLAGS="-mtune=cortex-a7 -mfpu=neon -mfloat-abi=hard -marm -O3 -Wall" all 
endef

define HIFIBERRY_MEASUREMENTS_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0555 $(@D)/analyze \
           $(TARGET_DIR)/opt/hifiberry/bin/fft-analzye
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/audio-inputs \
           $(TARGET_DIR)/opt/hifiberry/bin/audio-inputs
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/supported-mics \
	   $(TARGET_DIR)/opt/hifiberry/bin/supported-mics
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/record-sweep \
           $(TARGET_DIR)/opt/hifiberry/bin/record-sweep
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/room-measure \
           $(TARGET_DIR)/opt/hifiberry/bin/room-measure
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/input-level \
           $(TARGET_DIR)/opt/hifiberry/bin/input-level
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/run-measurement \
           $(TARGET_DIR)/opt/hifiberry/bin/run-measurement
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/roomeq-preset \
	   $(TARGET_DIR)/opt/hifiberry/bin/roomeq-preset
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/roomeq-range \
	   $(TARGET_DIR)/opt/hifiberry/bin/roomeq-range
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/roomeq-optimize \
	   $(TARGET_DIR)/opt/hifiberry/bin/roomeq-optimize
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/roomeq.conf \
    	   $(TARGET_DIR)/etc/roomeq.conf
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-measurements/frequency-demo.json \
	   $(TARGET_DIR)/opt/hifiberry/contrib/frequency-demo.json
endef

define HIFIBERRY_MEASUREMENTS_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
