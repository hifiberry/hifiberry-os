################################################################################
#
# hifiberry-gstreamer
#
################################################################################

HIFIBERRY_GSTREAMER_DEPENDENCIES += gstreamer1 gst1-plugins-base gst1-plugins-good gst1-plugins-bad gst1-plugins-ugly

define HIFIBERRY_GSTREAMER_INSTALL_EXTRA_FILES
	echo "Hack: Copying compiled typelib files"
	if [ ! -d $(TARGET_DIR)/usr/lib/girepository-1.0 ]; then \
		mkdir -p $(TARGET_DIR)/usr/lib/girepository-1.0; \
	fi
	cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-gstreamer/typelib/* \
        	$(TARGET_DIR)/usr/lib/girepository-1.0
endef

HIFIBERRY_GSTREAMER_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_GSTREAMER_INSTALL_EXTRA_FILES

$(eval $(generic-package))
