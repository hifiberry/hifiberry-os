################################################################################
#
# python-scramp
#
################################################################################

PYTHON_SCRAMP_VERSION = 1.2.0
PYTHON_SCRAMP_SOURCE = scramp-$(PYTHON_SCRAMP_VERSION).tar.gz
PYTHON_SCRAMP_SITE = https://files.pythonhosted.org/packages/58/c6/f077e1f4fb40d7a56662dd6874527e7f9d626323a1cd7261d59abeb52789
PYTHON_SCRAMP_SETUP_TYPE = setuptools
PYTHON_SCRAMP_LICENSE = MIT
PYTHON_SCRAMP_LICENSE_FILES = LICENSE

$(eval $(python-package))
