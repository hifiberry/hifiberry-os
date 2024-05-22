################################################################################
#
# python-pymcuprog
#
################################################################################

#PYTHON_PYMCUPROG_VERSION = dfa0f9b4352c41dbd58d32f3f091517112a1908c
PYTHON_PYMCUPROG_VERSION = dbd4904c8208797a05c4beb6649a3bd58f2ae662
PYTHON_PYMCUPROG_SITE = $(call github,microchip-pic-avr-tools,pymcuprog,$(PYTHON_PYMCUPROG_VERSION))
PYTHON_PYMCUPROG_SETUP_TYPE = setuptools

$(eval $(python-package))
