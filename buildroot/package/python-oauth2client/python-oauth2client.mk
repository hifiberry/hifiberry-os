################################################################################
#
# python-oauth2client
#
################################################################################

PYTHON_OAUTH2CLIENT_VERSION = 4.1.3
PYTHON_OAUTH2CLIENT_SOURCE = oauth2client-$(PYTHON_OAUTH2CLIENT_VERSION).tar.gz
PYTHON_OAUTH2CLIENT_SITE = https://files.pythonhosted.org/packages/a6/7b/17244b1083e8e604bf154cf9b716aecd6388acd656dd01893d0d244c94d9
PYTHON_OAUTH2CLIENT_SETUP_TYPE = setuptools
PYTHON_OAUTH2CLIENT_LICENSE = Apache-2.0
PYTHON_OAUTH2CLIENT_LICENSE_FILES = LICENSE

$(eval $(python-package))
