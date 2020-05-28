################################################################################
#
# dspprofiles
#
################################################################################

DSP_PROFILE_VERSION=10
define DSPPROFILES_INSTALL_TARGET_CMDS
     -mkdir -p $(TARGET_DIR)/opt/beocreate/beo-dsp-programs
     -mkdir -p $(TARGET_DIR)/opt/hifiberry/contrib
     # Create a copy of the Beocrate profile for the DAC+ DSP
#     cp $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/beocreate-universal-$(DSP_PROFILE_VERSION).xml \
#	     $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml
#     cp $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/beocreate-universal-$(DSP_PROFILE_VERSION).xml \
#	     $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml.orig

     # Default settings
#     dsptoolkit store-settings $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/beocreate.settings \
#             $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/beocreate-universal-$(DSP_PROFILE_VERSION).xml

     # Patch to Beocreate profile to become a DAC+ DSP profile
#     $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/beocreate2dacdsp.sh \
#	     $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml
#     dsptoolkit store-settings $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/dspdac.settings \
#	     $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml

     # Patching seems to be buggy at the moment, use local file
     cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/dspdac-$(DSP_PROFILE_VERSION).xml \
	     $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/dacdsp-universal-$(DSP_PROFILE_VERSION).xml

     # Temporary script to set I2S for DSP module
     $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/dsp-i2s-slave \
	     $(TARGET_DIR)/opt/hifiberry/contrib/dsp-i2s-slave
endef

$(eval $(generic-package))
