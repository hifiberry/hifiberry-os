################################################################################
#
# python-musicbrainz-ngs
#
################################################################################

PYTHON_MUSICBRAINZ_NGS_VERSION = 0.7.1
PYTHON_MUSICBRAINZ_NGS_SOURCE = v$(PYTHON_MUSICBRAINZ_NGS_VERSION).tar.gz
PYTHON_MUSICBRAINZ_NGS_SITE = https://github.com/alastair/python-musicbrainzngs/archive
PYTHON_MUSICBRAINZ_NGS_SETUP_TYPE = setuptools

$(eval $(python-package))
