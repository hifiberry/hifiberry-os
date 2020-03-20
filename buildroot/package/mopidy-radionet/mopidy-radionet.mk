################################################################################
#
# mopidy-radionet
#
################################################################################

MOPIDY_RADIONET_VERSION = 0.2.0
MOPIDY_RADIONET_SOURCE = Mopidy-RadioNet-$(MOPIDY_RADIONET_VERSION).tar.gz
MOPIDY_RADIONET_SITE = https://files.pythonhosted.org/packages/40/d5/f86c9fb527bebacf48658dd94360a5934cd412ac4e7e38b6bbc62969ea99
MOPIDY_RADIONET_SETUP_TYPE = setuptools

$(eval $(python-package))
