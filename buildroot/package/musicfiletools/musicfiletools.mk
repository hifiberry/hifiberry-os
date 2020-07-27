################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = cec29b5e59f558b528b26348999d6548d3bf3dee
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
