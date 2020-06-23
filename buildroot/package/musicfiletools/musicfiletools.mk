################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = d2042fd264ed2077ff310dca48e1251f542de89f
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
