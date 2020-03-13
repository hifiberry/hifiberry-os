################################################################################
#
# dsp-promo
#
################################################################################

DSP_PROMO_VERSION = bcd09e273f59d530ccf233e28c53b0a1b94f2092
DSP_PROMO_SITE = $(call github,hifiberry,create-dsp-promo,$(DSP_PROMO_VERSION))

define DSP_PROMO_INSTALL_TARGET_CMDS
	mkdir -p  $(TARGET_DIR)/opt/beocreate/beo-extensions/dsp-promo
	cp -rv $(@D)/* $(TARGET_DIR)/opt/beocreate/beo-extensions/dsp-promo
endef

$(eval $(generic-package))
