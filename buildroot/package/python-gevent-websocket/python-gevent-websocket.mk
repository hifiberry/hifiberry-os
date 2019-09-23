################################################################################
#
# python-gevent-websocket
#
################################################################################

PYTHON_GEVENT_WEBSOCKET_VERSION = 0.10.1
PYTHON_GEVENT_WEBSOCKET_SOURCE = gevent-websocket-$(PYTHON_GEVENT_WEBSOCKET_VERSION).tar.gz
PYTHON_GEVENT_WEBSOCKET_SITE = https://files.pythonhosted.org/packages/98/d2/6fa19239ff1ab072af40ebf339acd91fb97f34617c2ee625b8e34bf42393
PYTHON_GEVENT_WEBSOCKET_SETUP_TYPE = setuptools
PYTHON_GEVENT_WEBSOCKET_LICENSE = Copyright 2011-2017 Jeffrey Gelens <jeffrey@noppo.pro>
PYTHON_GEVENT_WEBSOCKET_LICENSE_FILES = LICENSE

PYTHON_GEVENT_DEPENDENCIES = python-gevent

$(eval $(python-package))
