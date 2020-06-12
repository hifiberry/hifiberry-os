################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = 48f31a2eeacb0078dc32442336f9b9bdc3ee8d1f
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
