################################################################################
#
# python-bottle-websocket
#
################################################################################

PYTHON_BOTTLE_WEBSOCKET_VERSION = 0.2.9
PYTHON_BOTTLE_WEBSOCKET_SOURCE = bottle-websocket-$(PYTHON_BOTTLE_WEBSOCKET_VERSION).tar.gz
PYTHON_BOTTLE_WEBSOCKET_SITE = https://files.pythonhosted.org/packages/17/8e/a22666b4bb0a6e31de579504077df2b1c2f1438136777c728e6cfabef295
PYTHON_BOTTLE_WEBSOCKET_SETUP_TYPE = setuptools
PYTHON_BOTTLE_WEBSOCKET_LICENSE = MIT

$(eval $(python-package))
