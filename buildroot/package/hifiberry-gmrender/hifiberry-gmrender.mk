################################################################################
#
# hifiberry-gmrender
#
################################################################################

HIFIBERRY_GMRENDER_VERSION = master
HIFIBERRY_GMRENDER_SITE = $(call github,hifiberry,gmrender-resurrect,$(HIFIBERRY_GMRENDER_VERSION))
# Original distribution does not have default configure,
# so we need to autoreconf:
HIFIBERRY_GMRENDER_AUTORECONF = YES
HIFIBERRY_GMRENDER_LICENSE = GPL-2.0+
HIFIBERRY_GMRENDER_LICENSE_FILES = COPYING
HIFIBERRY_GMRENDER_DEPENDENCIES = gstreamer1 libupnp
HIFIBERRY_GMRENDER_CONF_ENV += LIBS="-lasound"

$(eval $(autotools-package))
