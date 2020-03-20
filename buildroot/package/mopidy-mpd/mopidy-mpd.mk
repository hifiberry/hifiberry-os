################################################################################
#
# mopidy-mpd
#
################################################################################

MOPIDY_MPD_VERSION = 3.0.0
MOPIDY_MPD_SOURCE = Mopidy-MPD-$(MOPIDY_MPD_VERSION).tar.gz
MOPIDY_MPD_SITE = https://files.pythonhosted.org/packages/10/a1/af1f72d84b07fbc9353b5c4a37540b59ee5072fcc2f1791f81386046f1f9
MOPIDY_MPD_SETUP_TYPE = setuptools

$(eval $(python-package))
