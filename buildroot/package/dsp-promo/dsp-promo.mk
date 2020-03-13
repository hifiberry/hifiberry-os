################################################################################
#
# dsp-promo
#
################################################################################

DSP_PROMO_VERSION = 4b695789a42f0c10c13b1b27ff47b93074402b5c
DSP_PROMO_SITE = $(call github,hifiberry,create-dsp-promo,$(DSP_PROMO_VERSION))

define DSP_PROMO_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/dsp-promo
	cp -rv $(@D)/* $(TARGET_DIR)/opt/beocreate/beo-extensions/dsp-promo
endef

$(eval $(generic-package))
