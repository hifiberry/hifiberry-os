################################################################################
#
# python-gevent
#
################################################################################

PYTHON_GEVENT_VERSION = 21.8.0
PYTHON_GEVENT_SOURCE = gevent-$(PYTHON_GEVENT_VERSION).tar.gz
PYTHON_GEVENT_SITE = https://files.pythonhosted.org/packages/33/2e/49317db0bbd846720ce15fd43641b17a208e6466c582ecbe845e35092ea2
PYTHON_GEVENT_SETUP_TYPE = setuptools
PYTHON_GEVENT_LICENSE = MIT
PYTHON_GEVENT_LICENSE_FILES = LICENSE deps/c-ares/LICENSE.md deps/libev/LICENSE deps/libuv/LICENSE
PYTHON_GEVENT_ENV = GEVENTSETUP_EMBED=0
PYTHON_GEVENT_DEPENDENCIES = libevdev libev libuv c-ares

$(eval $(python-package))
