################################################################################
#
# python-cachetools
#
################################################################################

PYTHON_CACHETOOLS_VERSION = 4.0.0
PYTHON_CACHETOOLS_SOURCE = cachetools-$(PYTHON_CACHETOOLS_VERSION).tar.gz
PYTHON_CACHETOOLS_SITE = https://files.pythonhosted.org/packages/ff/e9/879bc23137b5c19f93c2133a6063874b83c8e1912ff1467a3d4331598921
PYTHON_CACHETOOLS_SETUP_TYPE = setuptools

$(eval $(python-package))
