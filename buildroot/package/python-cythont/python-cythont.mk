################################################################################
#
# python-cythont
#
################################################################################

PYTHON_CYTHONT_VERSION = 0.29.24
PYTHON_CYTHONT_SOURCE = Cython-$(PYTHON_CYTHONT_VERSION).tar.gz
PYTHON_CYTHONT_SITE = https://files.pythonhosted.org/packages/59/e3/78c921adf4423fff68da327cc91b73a16c63f29752efe7beb6b88b6dd79d
PYTHON_CYTHONT_SETUP_TYPE = setuptools
PYTHON_CYTHONT_LICENSE = Apache-2.0
PYTHON_CYTHONT_LICENSE_FILES = COPYING.txt LICENSE.txt

$(eval $(python-package))
