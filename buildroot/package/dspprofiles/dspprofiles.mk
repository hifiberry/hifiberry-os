################################################################################
#
# dspprofiles
#
################################################################################

define DSPPROFILES_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/generic192.xml \
           $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/generic192.xml
    $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dspprofiles/generic96.xml \
           $(TARGET_DIR)/opt/beocreate/beo-dsp-programs/generic192.xml
endef

$(eval $(generic-package))
