################################################################################
#
# python-gstreamer-player
#
################################################################################

PYTHON_GSTREAMER_PLAYER_VERSION = 1.1.2
PYTHON_GSTREAMER_PLAYER_SOURCE = gstreamer-player-$(PYTHON_GSTREAMER_PLAYER_VERSION).tar.gz
PYTHON_GSTREAMER_PLAYER_SITE = https://files.pythonhosted.org/packages/ac/57/17ab891edcf513d7254df70281ec14163f3154e2daf80e40a71f9bb28b73
PYTHON_GSTREAMER_PLAYER_SETUP_TYPE = setuptools
PYTHON_GSTREAMER_PLAYER_LICENSE = MIT

$(eval $(python-package))
