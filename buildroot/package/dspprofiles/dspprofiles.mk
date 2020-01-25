################################################################################
#
# dspprofiles
#
################################################################################

DSP_PROFILE_VERSION=10
define DSPPROFILES_INSTALL_TARGET_CMDS
     # Create a copy of the Beocrate profile for the DAC+ DSP
     cp $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/beocreate-universal-$(DSP_PROFILE_VERSION).xml \
	     $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml

     # Default settings
     dsptoolkit store-settings $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/beocreate.settings \
             $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/beocreate-universal-$(DSP_PROFILE_VERSION).xml

     # Patch to Beocreate profile to become a DAC+ DSP profile
     $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/beocreate2dacdsp.sh \
	     $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml
     dsptoolkit store-settings $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/dspdac.settings \
	                  $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml
endef

$(eval $(generic-package))
