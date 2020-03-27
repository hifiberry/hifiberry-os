################################################################################
#
# mopidy-iris
#
################################################################################

MOPIDY_IRIS_VERSION = 3.46.0
MOPIDY_IRIS_SOURCE = Mopidy-Iris-$(MOPIDY_IRIS_VERSION).tar.gz
MOPIDY_IRIS_SITE = https://files.pythonhosted.org/packages/b5/ff/8fa5998d619e0d97b813fde7d35f33454c558e5e3bf2f5a484a96554546b
MOPIDY_IRIS_SETUP_TYPE = setuptools

$(eval $(python-package))
