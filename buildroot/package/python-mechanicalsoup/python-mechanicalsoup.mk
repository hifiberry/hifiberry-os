################################################################################
#
# python-mechanicalsoup
#
################################################################################

PYTHON_MECHANICALSOUP_VERSION = 0.12.0
PYTHON_MECHANICALSOUP_SOURCE = MechanicalSoup-$(PYTHON_MECHANICALSOUP_VERSION).tar.gz
PYTHON_MECHANICALSOUP_SITE = https://files.pythonhosted.org/packages/c3/f7/68b90159109031391aa0872f611aebeca425aa432d26a74ea28aad43e969
PYTHON_MECHANICALSOUP_SETUP_TYPE = setuptools
PYTHON_MECHANICALSOUP_LICENSE = MIT
PYTHON_MECHANICALSOUP_LICENSE_FILES = LICENSE

$(eval $(python-package))
