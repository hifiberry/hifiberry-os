################################################################################
#
# python-proboscis
#
################################################################################

PYTHON_PROBOSCIS_VERSION = 1.2.6.0
PYTHON_PROBOSCIS_SOURCE = proboscis-$(PYTHON_PROBOSCIS_VERSION).tar.gz
PYTHON_PROBOSCIS_SITE = https://files.pythonhosted.org/packages/3c/c8/c187818ab8d0faecdc3c16c1e0b2e522f3b38570f0fb91dcae21662019d0
PYTHON_PROBOSCIS_SETUP_TYPE = setuptools
PYTHON_PROBOSCIS_LICENSE = Apache-2.0

$(eval $(python-package))
