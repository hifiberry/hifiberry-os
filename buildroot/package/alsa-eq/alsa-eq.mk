#############################################################
#
# alsa-eq
#
#############################################################
ALSA_EQ_VERSION = 0.6
ALSA_EQ_SOURCE = alsaequal-$(ALSA_EQ_VERSION).tar.bz2
ALSA_EQ_SITE = https://thedigitalmachine.net/tools
ALSA_EQ_DEPENDENCIES = caps

define ALSA_EQ_BUILD_CMDS
	cd $(@D) && CC=$(TARGET_CC) LD=$(TARGET_CC) make
	echo "alsaeq make done"
	sleep 1
endef

define ALSA_EQ_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/lib/alsa-lib
	$(INSTALL) -D -m 755 $(@D)/libasound_module_ctl_equal.so \
           $(TARGET_DIR)/usr/lib/alsa-lib/
	$(INSTALL) -D -m 755 $(@D)/libasound_module_pcm_equal.so \
           $(TARGET_DIR)/usr/lib/alsa-lib/
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/alsa-eq/asound.conf.eq \
           $(TARGET_DIR)/etc/asound.conf.eq
endef

$(eval $(generic-package))
