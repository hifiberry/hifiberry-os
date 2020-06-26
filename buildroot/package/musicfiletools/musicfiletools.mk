################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = 181cbec7b5dac70f04931288aa809fbdbb37b5fb
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
