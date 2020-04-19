################################################################################
#
# mopidy-local
#
################################################################################

MOPIDY_LOCAL_VERSION = 3.1.1
MOPIDY_LOCAL_SOURCE = Mopidy-Local-$(MOPIDY_LOCAL_VERSION).tar.gz
MOPIDY_LOCAL_SITE = https://files.pythonhosted.org/packages/03/a9/650dfbd029d38ff38b8bd1c8516ae91272a800f60d1289746cd070ba7b01
MOPIDY_LOCAL_SETUP_TYPE = setuptools

$(eval $(python-package))
