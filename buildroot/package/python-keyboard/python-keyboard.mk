################################################################################
#
# python-keyboard
#
################################################################################

PYTHON_KEYBOARD_VERSION = 0.13.2
PYTHON_KEYBOARD_SITE = $(call github,boppreh,keyboard,master)
PYTHON_KEYBOARD_SETUP_TYPE = setuptools
PYTHON_KEYBOARD_LICENSE = MIT
PYTHON_KEYBOARD_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
