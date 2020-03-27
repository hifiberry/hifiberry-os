################################################################################
#
# python-validictory
#
################################################################################

PYTHON_VALIDICTORY_VERSION = 1.1.2
PYTHON_VALIDICTORY_SOURCE = validictory-$(PYTHON_VALIDICTORY_VERSION).tar.gz
PYTHON_VALIDICTORY_SITE = https://files.pythonhosted.org/packages/c9/c6/59d4273279df9f942f34cf45b9031c109a51d8e5682ca7975a9e1ae71080
PYTHON_VALIDICTORY_SETUP_TYPE = setuptools
PYTHON_VALIDICTORY_LICENSE = FIXME: please specify the exact BSD version
PYTHON_VALIDICTORY_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
