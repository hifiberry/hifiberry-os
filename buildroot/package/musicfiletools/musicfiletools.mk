################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = 554c31c18cce7c1aea1d7e15c603a5f5dbd40bd0
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
