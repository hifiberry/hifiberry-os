################################################################################
#
# hifiberry-gmrender
#
################################################################################

HIFIBERRY_GMRENDER_VERSION = 0.0.8
HIFIBERRY_GMRENDER_SITE = $(call github,hzeller,gmrender-resurrect,v$(GMRENDER_RESURRECT_VERSION))
# Original distribution does not have default configure,
# so we need to autoreconf:
HIFIBERRY_GMRENDER_AUTORECONF = YES
HIFIBERRY_GMRENDER_LICENSE = GPL-2.0+
HIFIBERRY_GMRENDER_LICENSE_FILES = COPYING
HIFIBERRY_GMRENDER_DEPENDENCIES = \
	gstreamer1 \
	$(if $(BR2_PACKAGE_LIBUPNP),libupnp,libupnp18)

$(eval $(autotools-package))
