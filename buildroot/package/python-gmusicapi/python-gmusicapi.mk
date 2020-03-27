################################################################################
#
# python-gmusicapi
#
################################################################################

PYTHON_GMUSICAPI_VERSION = 12.1.1
PYTHON_GMUSICAPI_SOURCE = gmusicapi-$(PYTHON_GMUSICAPI_VERSION).tar.gz
PYTHON_GMUSICAPI_SITE = https://files.pythonhosted.org/packages/9b/8d/acd05b2518ec87fc4634d55dcd70496cb030eca4d966b0a90747cf45600e
PYTHON_GMUSICAPI_SETUP_TYPE = setuptools
PYTHON_GMUSICAPI_LICENSE = FIXME: please specify the exact BSD version
PYTHON_GMUSICAPI_LICENSE_FILES = LICENSE

$(eval $(python-package))
