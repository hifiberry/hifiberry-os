################################################################################
#
# dsp-promo
#
################################################################################

DSP_PROMO_VERSION = 0963a320266f134f309a14894aefa6fe3b2486cc
DSP_PROMO_SITE = $(call github,hifiberry,create-dsp-promo,$(DSP_PROMO_VERSION))

DSP_PROMO_DEPENDENCIES = beocreate

define DSP_PROMO_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/dsp-promo
	cp -rv $(@D)/* $(TARGET_DIR)/opt/beocreate/beo-extensions/dsp-promo
endef

$(eval $(generic-package))
