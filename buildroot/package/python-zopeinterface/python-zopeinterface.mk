################################################################################
#
# python-zopeinterface
#
################################################################################

PYTHON_ZOPEINTERFACE_VERSION = 5.4.0
PYTHON_ZOPEINTERFACE_SOURCE = zope.interface-$(PYTHON_ZOPEINTERFACE_VERSION).tar.gz
PYTHON_ZOPEINTERFACE_SITE = https://files.pythonhosted.org/packages/ae/58/e0877f58daa69126a5fb325d6df92b20b77431cd281e189c5ec42b722f58
PYTHON_ZOPEINTERFACE_SETUP_TYPE = setuptools
PYTHON_ZOPEINTERFACE_LICENSE = ZPL
PYTHON_ZOPEINTERFACE_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
