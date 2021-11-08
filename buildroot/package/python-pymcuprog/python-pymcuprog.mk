################################################################################
#
# python-pymcuprog
#
################################################################################

PYTHON_PYMCUPROG_VERSION = dfa0f9b4352c41dbd58d32f3f091517112a1908c
PYTHON_PYMCUPROG_SITE = $(call github,microchip-pic-avr-tools,pymcuprog,$(PYTHON_PYMCUPROG_VERSION))
PYTHON_PYMCUPROG_SETUP_TYPE = setuptools

$(eval $(python-package))
