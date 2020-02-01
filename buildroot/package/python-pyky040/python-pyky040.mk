################################################################################
#
# python-pyky040
#
################################################################################

PYTHON_PYKY040_VERSION = 0.1.3
PYTHON_PYKY040_SOURCE = pyky040-$(PYTHON_PYKY040_VERSION).tar.gz
PYTHON_PYKY040_SITE = https://files.pythonhosted.org/packages/56/14/e514d1e786cf468c8d269ac15a65e8dd6c116bab2b90d4f0c5a90da55e7f
PYTHON_PYKY040_SETUP_TYPE = setuptools
PYTHON_PYKY040_LICENSE = 

$(eval $(python-package))
