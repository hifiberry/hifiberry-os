################################################################################
#
# python-pg8000
#
################################################################################

PYTHON_PG8000_VERSION = 1.16.0
PYTHON_PG8000_SOURCE = pg8000-$(PYTHON_PG8000_VERSION).tar.gz
PYTHON_PG8000_SITE = https://files.pythonhosted.org/packages/f9/37/456b51ecde0cf36f8b8004f9d1cd02778bccc46bcffccdf714c9545337f4
PYTHON_PG8000_SETUP_TYPE = setuptools
PYTHON_PG8000_LICENSE = BSD-3-Clause
PYTHON_PG8000_LICENSE_FILES = LICENSE

$(eval $(python-package))
