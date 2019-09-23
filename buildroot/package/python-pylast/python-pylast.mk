################################################################################
#
# python-pylast
#
################################################################################

PYTHON_PYLAST_VERSION = 3.1.0
PYTHON_PYLAST_SOURCE = pylast-$(PYTHON_PYLAST_VERSION).tar.gz
PYTHON_PYLAST_SITE = https://files.pythonhosted.org/packages/c1/3b/05414f6c406d571604a6ee19530ba0a0bd35a8c2cae158ffac0caaa74179
PYTHON_PYLAST_SETUP_TYPE = setuptools
PYTHON_PYLAST_LICENSE = Apache-2.0
PYTHON_PYLAST_LICENSE_FILES = COPYING

$(eval $(python-package))
