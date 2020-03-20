################################################################################
#
# mopidy-spotify
#
################################################################################

MOPIDY_SPOTIFY_VERSION = 4.0.1
MOPIDY_SPOTIFY_SOURCE = Mopidy-Spotify-$(MOPIDY_SPOTIFY_VERSION).tar.gz
MOPIDY_SPOTIFY_SITE = https://files.pythonhosted.org/packages/f2/d2/0ce7f0f948fa91175bc34b23be9c4c70323d121acb4cc089bd72fc2769df
MOPIDY_SPOTIFY_SETUP_TYPE = setuptools

$(eval $(python-package))
