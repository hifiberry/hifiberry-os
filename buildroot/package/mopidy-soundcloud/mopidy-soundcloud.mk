################################################################################
#
# mopidy-soundcloud
#
################################################################################

MOPIDY_SOUNDCLOUD_VERSION = 3.0.0
MOPIDY_SOUNDCLOUD_SOURCE = Mopidy-SoundCloud-$(MOPIDY_SOUNDCLOUD_VERSION).tar.gz
MOPIDY_SOUNDCLOUD_SITE = https://files.pythonhosted.org/packages/83/55/58ddb9770ed9bd0fcf765a486f15261d78265562bf208f9dc3f5dab55166
MOPIDY_SOUNDCLOUD_SETUP_TYPE = setuptools

$(eval $(python-package))
