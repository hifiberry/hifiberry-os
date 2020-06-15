################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = eac68f01abb5b35ced377aabb5bf513471e69fed
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
