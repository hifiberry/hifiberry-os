################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION = a5c4320c381203ba459b8e65fd909f7df5be0713
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
