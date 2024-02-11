################################################################################
#
# python-discid
#
################################################################################

PYTHON_DISCID_VERSION = v1.2.0
PYTHON_DISCID_SITE = $(call github,JonnyJD,python-discid,$(PYTHON_DISCID_VERSION))
PYTHON_DISCID_SETUP_TYPE = distutils

$(eval $(python-package))
