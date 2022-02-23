################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = 905b5af0fb822403d0249f5454bc431cd60f573a
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
