################################################################################
#
# python-hidapi
#
################################################################################

PYTHON_HIDAPI_VERSION = 0.10.1
PYTHON_HIDAPI_SOURCE = hidapi-$(PYTHON_HIDAPI_VERSION).tar.gz
PYTHON_HIDAPI_SITE = https://files.pythonhosted.org/packages/99/9b/5c41756461308a5b2d8dcbcd6eaa2f1c1bc60f0a6aa743b58cab756a92e1
PYTHON_HIDAPI_SETUP_TYPE = setuptools
PYTHON_HIDAPI_LICENSE = FIXME: please specify the exact BSD version, GNU General Public License v3 (GPLv3)
PYTHON_HIDAPI_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
