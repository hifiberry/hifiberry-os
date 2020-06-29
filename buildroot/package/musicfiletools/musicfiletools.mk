################################################################################
#
# musicfiletools
#
################################################################################

MUSICFILETOOLS_VERSION =  83bc8bda365fdbd4cd3f80c8daa3c5441f2e401a
MUSICFILETOOLS_SITE = $(call github,hifiberry,musicfiletools,$(MUSICFILETOOLS_VERSION))
MUSICFILETOOLS_SETUP_TYPE = setuptools
MUSICFILETOOLS_LICENSE = MIT
MUSICFILETOOLS_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
