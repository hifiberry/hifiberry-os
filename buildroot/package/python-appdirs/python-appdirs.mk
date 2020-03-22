################################################################################
#
# python-appdirs
#
################################################################################

PYTHON_APPDIRS_VERSION = 1.4.3
PYTHON_APPDIRS_SOURCE = appdirs-$(PYTHON_APPDIRS_VERSION).tar.gz
PYTHON_APPDIRS_SITE = https://files.pythonhosted.org/packages/48/69/d87c60746b393309ca30761f8e2b49473d43450b150cb08f3c6df5c11be5
PYTHON_APPDIRS_SETUP_TYPE = setuptools
PYTHON_APPDIRS_LICENSE = MIT
PYTHON_APPDIRS_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
