################################################################################
#
# mopidy-gmusic
#
################################################################################

MOPIDY_GMUSIC_VERSION = 4.0.0
MOPIDY_GMUSIC_SOURCE = Mopidy-GMusic-$(MOPIDY_GMUSIC_VERSION).tar.gz
MOPIDY_GMUSIC_SITE = https://files.pythonhosted.org/packages/d2/37/5cd9874a21bf06db747fd7264dc07938c1e1ccf9b80ec68a2ef6e8350c64
MOPIDY_GMUSIC_SETUP_TYPE = setuptools

$(eval $(python-package))
