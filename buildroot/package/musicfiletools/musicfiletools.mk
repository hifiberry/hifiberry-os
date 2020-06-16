################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = 0eb19ab6e5bec5c31283deaff6e1920899789441
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
