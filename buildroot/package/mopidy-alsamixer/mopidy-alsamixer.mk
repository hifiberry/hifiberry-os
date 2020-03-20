################################################################################
#
# mopidy-alsamixer
#
################################################################################

MOPIDY_ALSAMIXER_VERSION = 2.0.0
MOPIDY_ALSAMIXER_SOURCE = Mopidy-ALSAMixer-$(MOPIDY_ALSAMIXER_VERSION).tar.gz
MOPIDY_ALSAMIXER_SITE = https://files.pythonhosted.org/packages/b9/66/e43534c100f48f0779191d3e7819e909ce39eff7f8eba71dc218897131fc
MOPIDY_ALSAMIXER_SETUP_TYPE = setuptools

$(eval $(python-package))
