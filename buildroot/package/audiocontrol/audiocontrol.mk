################################################################################
#
# audiocontrol
#
################################################################################

AUDIOCONTROL_VERSION = 0.3
AUDIOCONTROL_SOURCE = audiocontrol-$(AUDIOCONTROL_VERSION).tar.gz
AUDIOCONTROL_SITE = https://github.com/hifiberry/audiocontrol/raw/master/dist
AUDIOCONTROL_SETUP_TYPE = setuptools
AUDIOCONTROL_LICENSE = MIT
AUDIOCONTROL_LICENSE_FILES = LICENSE.md

define AUDIOCONTROL_INSTALL_INIT_SYSV
	pwd
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol/S91audiocontrol \
		$(TARGET_DIR)/etc/init.d/S91audiocontrol
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol/audiocontrol.conf \
           $(TARGET_DIR)/etc
endef

define AUDIOCONTROL_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol/audiocontrol.service \
                $(TARGET_DIR)/lib/systemd/system/audiocontrol.service
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/audiocontrol/audiocontrol.conf \
           $(TARGET_DIR)/etc
endef

AUDIOCONTROL_POST_INSTALL_STAGING_HOOKS += AUDIOCONTROL_INSTALL_INIT_SYSV

$(eval $(python-package))
