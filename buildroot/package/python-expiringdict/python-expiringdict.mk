################################################################################
#
# python-expiringdict
#
################################################################################

PYTHON_EXPIRINGDICT_VERSION = 1.1.4
PYTHON_EXPIRINGDICT_SOURCE = expiringdict-$(PYTHON_EXPIRINGDICT_VERSION).tar.gz
PYTHON_EXPIRINGDICT_SITE = https://files.pythonhosted.org/packages/fc/71/f3fe348cb85678c6cce5b96210efa099c2a1994ddfc3f37db5aedf8426de
PYTHON_EXPIRINGDICT_SETUP_TYPE = setuptools
PYTHON_EXPIRINGDICT_LICENSE = Apache 2
PYTHON_EXPIRINGDICT_LICENSE_FILES = LICENSE

$(eval $(python-package))
