################################################################################
#
# python-bs4
#
################################################################################

PYTHON_BS4_VERSION = 0.0.1
PYTHON_BS4_SOURCE = bs4-$(PYTHON_BS4_VERSION).tar.gz
PYTHON_BS4_SITE = https://files.pythonhosted.org/packages/10/ed/7e8b97591f6f456174139ec089c769f89a94a1a4025fe967691de971f314
PYTHON_BS4_SETUP_TYPE = setuptools
PYTHON_BS4_LICENSE = 

$(eval $(python-package))
