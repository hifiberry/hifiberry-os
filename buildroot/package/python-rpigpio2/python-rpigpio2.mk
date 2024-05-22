################################################################################
#
# RPi.GPIO2
#
################################################################################


PYTHON_RPIGPIO2_VERSION = 0323b9e715b15b402f0b189aac6c2082fea28ded
PYTHON_RPIGPIO2_SITE = $(call github,underground-software,RPi.GPIO2,$(PYTHON_RPIGPIO2_VERSION))

PYTHON_RPIGPIO2_DEPENDENCIES = host-python3

PYTHON_RPIGPIO2_SETUP_TYPE = setuptools

$(eval $(python-package))
