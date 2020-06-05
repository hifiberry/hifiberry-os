################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = a291fc022a95b5d2bf9938e969e5b8d6acd9c5df
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
