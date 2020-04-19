################################################################################
#
# mopidy-musicbox-webclient
#
################################################################################

MOPIDY_MUSICBOX_WEBCLIENT_VERSION = 3.0.1
MOPIDY_MUSICBOX_WEBCLIENT_SOURCE = Mopidy-MusicBox-Webclient-$(MOPIDY_MUSICBOX_WEBCLIENT_VERSION).tar.gz
MOPIDY_MUSICBOX_WEBCLIENT_SITE = https://files.pythonhosted.org/packages/90/b9/ffdbb35edcaeb7b957a0bf0c19134e4da7eec12826596761180fdfda2461
MOPIDY_MUSICBOX_WEBCLIENT_SETUP_TYPE = setuptools

$(eval $(python-package))
