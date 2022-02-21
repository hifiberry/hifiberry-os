################################################################################
#
# python-zopeevent
#
################################################################################

PYTHON_ZOPEEVENT_VERSION = 4.5.0
PYTHON_ZOPEEVENT_SOURCE = zope.event-$(PYTHON_ZOPEEVENT_VERSION).tar.gz
PYTHON_ZOPEEVENT_SITE = https://files.pythonhosted.org/packages/30/00/94ed30bfec18edbabfcbd503fcf7482c5031b0fbbc9bc361f046cb79781c
PYTHON_ZOPEEVENT_SETUP_TYPE = setuptools
PYTHON_ZOPEEVENT_LICENSE = ZPL
PYTHON_ZOPEEVENT_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
