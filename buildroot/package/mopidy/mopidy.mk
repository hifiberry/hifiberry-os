################################################################################
#
# mopidy
#
################################################################################

MOPIDY_VERSION = 3.0.1
MOPIDY_SOURCE = Mopidy-$(MOPIDY_VERSION).tar.gz
MOPIDY_SITE = https://files.pythonhosted.org/packages/85/08/fbe06c920f4443b3ce1d6579050a2fac5132538977762f0d4873c098c8d1
MOPIDY_SETUP_TYPE = setuptools

define MOPIDY_INSTALL_TARGET_CMDS
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/mopidy/mopidy.conf \
                $(TARGET_DIR)/etc/mopidy.conf
endef

define MOPIDY_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/mopidy/mopidy.service \
                $(TARGET_DIR)/usr/lib/systemd/system/mopidy.service
        ln -fs ../../../../usr/lib/systemd/system/mopidy.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/mopidy.service
endef

$(eval $(python-package))
