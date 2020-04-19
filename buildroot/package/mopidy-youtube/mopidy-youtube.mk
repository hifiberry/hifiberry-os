################################################################################
#
# mopidy-youtube
#
################################################################################

MOPIDY_YOUTUBE_VERSION = 3.0
MOPIDY_YOUTUBE_SOURCE = Mopidy-YouTube-$(MOPIDY_YOUTUBE_VERSION).tar.gz
MOPIDY_YOUTUBE_SITE = https://files.pythonhosted.org/packages/98/f4/d9278e742ea2792431cd7d94d55094d9f87324e018185532e3da570cde98
MOPIDY_YOUTUBE_SETUP_TYPE = setuptools

$(eval $(python-package))
