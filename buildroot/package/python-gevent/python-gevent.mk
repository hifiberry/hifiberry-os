################################################################################
#
# python-gevent
#
################################################################################

PYTHON_GEVENT_VERSION = 22.10.2
PYTHON_GEVENT_SOURCE = gevent-$(PYTHON_GEVENT_VERSION).tar.gz
PYTHON_GEVENT_SITE = https://files.pythonhosted.org/packages/9f/4a/e9e57cb9495f0c7943b1d5965c4bdd0d78bc4a433a7c96ee034b16c01520
PYTHON_GEVENT_SETUP_TYPE = setuptools
PYTHON_GEVENT_LICENSE = MIT
PYTHON_GEVENT_LICENSE_FILES = LICENSE deps/c-ares/LICENSE.md deps/libev/LICENSE deps/libuv/LICENSE
PYTHON_GEVENT_ENV = GEVENTSETUP_EMBED=0
PYTHON_GEVENT_DEPENDENCIES = libevdev libev libuv c-ares

$(eval $(python-package))
