################################################################################
#
# hifiberry-gmrender
#
################################################################################

#HIFIBERRY_GMRENDER_VERSION = bfd6d4e251e69169c6920e62cc041e5cf32fef79
HIFIBERRY_GMRENDER_VERSION = 20a6928fab503fbbfbb2e80a9c1c4419f11777db # UpnpInit2 patch
HIFIBERRY_GMRENDER_SITE = $(call github,hifiberry,gmrender-resurrect,$(HIFIBERRY_GMRENDER_VERSION))
# Original distribution does not have default configure,
# so we need to autoreconf:
HIFIBERRY_GMRENDER_AUTORECONF = YES
HIFIBERRY_GMRENDER_LICENSE = GPL-2.0+
HIFIBERRY_GMRENDER_LICENSE_FILES = COPYING
HIFIBERRY_GMRENDER_DEPENDENCIES = gstreamer1 libupnp alsa-lib
HIFIBERRY_GMRENDER_CONF_ENV += LIBS="-lasound"

$(eval $(autotools-package))
