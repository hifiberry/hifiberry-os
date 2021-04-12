################################################################################
#
# python-blinker
#
################################################################################

PYTHON_BLINKER_VERSION = 1.4
PYTHON_BLINKER_SOURCE = blinker-$(PYTHON_BLINKER_VERSION).tar.gz
PYTHON_BLINKER_SITE = https://files.pythonhosted.org/packages/1b/51/e2a9f3b757eb802f61dc1f2b09c8c99f6eb01cf06416c0671253536517b6
PYTHON_BLINKER_SETUP_TYPE = setuptools
PYTHON_BLINKER_LICENSE = MIT
PYTHON_BLINKER_LICENSE_FILES = LICENSE

$(eval $(python-package))
