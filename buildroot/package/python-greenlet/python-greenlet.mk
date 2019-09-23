################################################################################
#
# python-greenlet
#
################################################################################

PYTHON_GREENLET_VERSION = 0.4.15
PYTHON_GREENLET_SOURCE = greenlet-$(PYTHON_GREENLET_VERSION).tar.gz
PYTHON_GREENLET_SITE = https://files.pythonhosted.org/packages/f8/e8/b30ae23b45f69aa3f024b46064c0ac8e5fcb4f22ace0dca8d6f9c8bbe5e7
PYTHON_GREENLET_SETUP_TYPE = distutils
PYTHON_GREENLET_LICENSE = MIT
PYTHON_GREENLET_LICENSE_FILES = LICENSE

#define PYTHON_GREENLET_EXTRACT_CMDS
#    $(UNZIP) -d $(@D) $(DL_DIR)/$(PYTHON_GREENLET_SOURCE)
#    mv $(@D)/greenlet-$(PYTHON_GREENLET_VERSION)/* $(@D)
#    $(RM) -r $(@D)/greenlet-$(PYTHON_GREENLET_VERSION)
#endef

#PYTHON_GREENLET_VERSION = 0.4.12
#PYTHON_GREENLET_SOURCE = greenlet-$(PYTHON_GREENLET_VERSION).tar.gz
#PYTHON_GREENLET_SITE = https://pypi.python.org/packages/be/76/82af375d98724054b7e273b5d9369346937324f9bcc20980b45b068ef0b0
#PYTHON_GREENLET_LICENSE = MIT
#PYTHON_GREENLET_LICENSE_FILES = LICENSE
#PYTHON_GREENLET_SETUP_TYPE = distutils

$(eval $(python-package))
