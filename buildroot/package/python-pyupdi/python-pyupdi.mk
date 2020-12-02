################################################################################
#
# python-pyupdi
#
################################################################################

PYTHON_PYUPDI_VERSION = c3d2486ad6fcd2b9d9f03710ef3601f1629bbc88
PYTHON_PYUPDI_SITE = $(call github,mraardvark,pyupdi,$(PYTHON_PYUPDI_VERSION))
PYTHON_PYUPDI_SETUP_TYPE = setuptools

$(eval $(python-package))
