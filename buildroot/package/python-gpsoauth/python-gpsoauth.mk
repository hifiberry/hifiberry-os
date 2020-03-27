################################################################################
#
# python-gpsoauth
#
################################################################################

PYTHON_GPSOAUTH_VERSION = 0.4.1
PYTHON_GPSOAUTH_SOURCE = gpsoauth-$(PYTHON_GPSOAUTH_VERSION).tar.gz
PYTHON_GPSOAUTH_SITE = https://files.pythonhosted.org/packages/96/a1/2b366c602ee081def4dd80624581dfa8eb23d20c5a51f8a2591c40fa8d41
PYTHON_GPSOAUTH_SETUP_TYPE = setuptools
PYTHON_GPSOAUTH_LICENSE = MIT

$(eval $(python-package))
