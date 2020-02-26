################################################################################
#
# python-usagedata
#
################################################################################

PYTHON_USAGEDATA_VERSION = a0edf6ac272f77892f4f797732f76d72bdbe7a1a
PYTHON_USAGEDATA_SITE = $(call github,hifiberry,usagecollector,$(PYTHON_USAGEDATA_VERSION))
PYTHON_USAGEDATA_SETUP_TYPE = setuptools
PYTHON_USAGEDATA_LICENSE = MIT
PYTHON_USAGEDATA_LICENSE_FILES = LICENSE.md

define PYTHON_USAGEDATA_POST_INSTALL_TARGET_CMD
endef

PYTHON_USAGEDATA_POST_INSTALL_TARGET_HOOKS += PYTHON_USAGEDATA_POST_INSTALL_TARGET_CMD

define PYTHON_USAGEDATA_INSTALL_INIT
endef

PYTHON_USAGEDATA_POST_INSTALL_TARGET_HOOKS += PYTHON_USAGEDATA_INSTALL_INIT

$(eval $(python-package))
