################################################################################
#
# python-pyedbglib
#
################################################################################

PYTHON_PYEDBGLIB_VERSION = b91b24ab19a6557a67dea9082616650c20c7a01f
PYTHON_PYEDBGLIB_SITE = $(call github,microchip-pic-avr-tools,pyedbglib,$(PYTHON_PYEDBGLIB_VERSION))
PYTHON_PYEDBGLIB_SETUP_TYPE = setuptools

$(eval $(python-package))
