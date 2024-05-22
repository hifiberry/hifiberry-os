################################################################################
#
# python-pyedbglib
#
################################################################################

PYTHON_PYEDBGLIB_VERSION = 9bbeceba942772ef31b9c059b761460a782313e6
PYTHON_PYEDBGLIB_SITE = $(call github,microchip-pic-avr-tools,pyedbglib,$(PYTHON_PYEDBGLIB_VERSION))
PYTHON_PYEDBGLIB_SETUP_TYPE = setuptools

$(eval $(python-package))
