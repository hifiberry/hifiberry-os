################################################################################
#
# python-evdev
#
################################################################################

PYTHON_EVDEV_VERSION = 1.6.0
PYTHON_EVDEV_SOURCE = evdev-$(PYTHON_EVDEV_VERSION).tar.gz
#PYTHON_EVDEV_SITE = https://files.pythonhosted.org/packages/4d/ec/bb298d36ed67abd94293253e3e52bdf16732153b887bf08b8d6f269eacef
PYTHON_EVDEV_SITE = https://files.pythonhosted.org/packages/dd/49/d75ac71f54c6c32ac3c63828541740db74d9c764a82496be97b82314d355
PYTHON_EVDEV_SETUP_TYPE = setuptools
PYTHON_EVDEV_LICENSE = FIXME: please specify the exact BSD version
PYTHON_EVDEV_LICENSE_FILES = LICENSE

PYTHON_EVDEV_BUILD_OPTS =  build_ecodes --evdev-headers ${BUILD_DIR}/linux-custom/include/uapi/linux/input.h:${BUILD_DIR}/linux-custom/include/uapi/linux/input-event-codes.h

$(eval $(python-package))
