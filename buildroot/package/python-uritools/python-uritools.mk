################################################################################
#
# python-uritools
#
################################################################################

PYTHON_URITOOLS_VERSION = 3.0.0
PYTHON_URITOOLS_SOURCE = uritools-$(PYTHON_URITOOLS_VERSION).tar.gz
PYTHON_URITOOLS_SITE = https://files.pythonhosted.org/packages/0e/16/f6c423dfe3e4a0e3bc00f4f2f540f3618a918b9b4fd0ec4ef51407931592
PYTHON_URITOOLS_SETUP_TYPE = setuptools

$(eval $(python-package))
