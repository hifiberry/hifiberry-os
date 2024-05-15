################################################################################
#
# libdiscid
#
################################################################################

LIBDISCID_VERSION = v0.6.4
LIBDISCID_SITE = $(call github,metabrainz,libdiscid,$(LIBDISCID_VERSION))
LIBDISCID_LICENSE = LGPL-2.1
LIBDISCID_LICENSE_FILES = README

$(eval $(cmake-package))
