################################################################################
#
# mopidy-mpris
#
################################################################################

MOPIDY_MPRIS_VERSION = 3.0.1
MOPIDY_MPRIS_SOURCE = Mopidy-MPRIS-$(MOPIDY_MPRIS_VERSION).tar.gz
MOPIDY_MPRIS_SITE = https://files.pythonhosted.org/packages/d8/1d/61871437a27eb06ddf8b5ca38854dcbb15d219aab7015876ce3f1ecf9756
MOPIDY_MPRIS_SETUP_TYPE = setuptools

$(eval $(python-package))
