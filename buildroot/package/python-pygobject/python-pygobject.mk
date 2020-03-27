################################################################################
#
# python-pygobject
#
################################################################################

PYTHON_PYGOBJECT_VERSION = 3.36.0
PYTHON_PYGOBJECT_SOURCE = PyGObject-$(PYTHON_PYGOBJECT_VERSION).tar.gz
PYTHON_PYGOBJECT_SITE = https://files.pythonhosted.org/packages/3e/b5/f4fd3351ed074aeeae30bff71428f38bc42187e34c44913239a9dc85a7fc
PYTHON_PYGOBJECT_SETUP_TYPE = setuptools
PYTHON_PYGOBJECT_LICENSE = GNU Lesser General Public License v2 or later (LGPLv2+)
PYTHON_PYGOBJECT_LICENSE_FILES = COPYING docs/images/LICENSE

PYTHON_PYGOBJECT_DEPENDENCIES += python3 host-python3 python-pycairo host-python-pycairo host-gstreamer1

PYTHON_PYGOBJECT_CONF_ENV = \
	PYTHON=$(HOST_DIR)/usr/bin/python3 \
	PYTHON_INCLUDES="`$(STAGING_DIR)/usr/bin/python3-config --includes`"

PYTHON_PYGOBJECT_CONF_OPTS += --with-ffi --with-gst

$(eval $(python-package))
