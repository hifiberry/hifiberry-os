################################################################################
#
# python-pyserial
#
################################################################################

PYTHON_PYSERIAL_VERSION = 3.4
PYTHON_PYSERIAL_SOURCE = pyserial-$(PYTHON_PYSERIAL_VERSION).tar.gz
PYTHON_PYSERIAL_SITE = https://files.pythonhosted.org/packages/cc/74/11b04703ec416717b247d789103277269d567db575d2fd88f25d9767fe3d
PYTHON_PYSERIAL_SETUP_TYPE = setuptools
PYTHON_PYSERIAL_LICENSE = FIXME: please specify the exact BSD version
PYTHON_PYSERIAL_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
