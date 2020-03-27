################################################################################
#
# python-pykka
#
################################################################################

PYTHON_PYKKA_VERSION = 2.0.2
PYTHON_PYKKA_SOURCE = Pykka-$(PYTHON_PYKKA_VERSION).tar.gz
PYTHON_PYKKA_SITE = https://files.pythonhosted.org/packages/8c/25/26af8b333bbc6b00bd03a95c058c50e6161af50680030a30cbdf053c4354
PYTHON_PYKKA_SETUP_TYPE = setuptools
PYTHON_PYKKA_LICENSE = Apache-2.0
PYTHON_PYKKA_LICENSE_FILES = LICENSE

$(eval $(python-package))
