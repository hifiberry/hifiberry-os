################################################################################
#
# dsptoolkit
#
################################################################################

DSPTOOLKIT_VERSION = ee453c2dee4d17a6f8adeb037dab46ecb8866a28
DSPTOOLKIT_SITE = $(call github,hifiberry,hifiberry-dsp,$(DSPTOOLKIT_VERSION))
DSPTOOLKIT_SETUP_TYPE = setuptools
DSPTOOLKIT_LICENSE = MIT
DSPTOOLKIT_LICENSE_FILES = LICENSE.md

define DSPTOOLKIT_POST_INSTALL_TARGET_CMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/sigmatcp.conf \
	            $(TARGET_DIR)/etc/sigmatcp.conf
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/dump-spdif-status.sh \
		                    $(TARGET_DIR)/opt/hifiberry/bin/dump-spdif-status
endef

DSPTOOLKIT_POST_INSTALL_TARGET_HOOKS += DSPTOOLKIT_POST_INSTALL_TARGET_CMD

define DSPTOOLKIT_INSTALL_INIT
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/S90sigmatcp \
		$(TARGET_DIR)/etc/init.d/S90sigmatcp
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/sigmatcp.service \
                $(TARGET_DIR)/usr/lib/systemd/system/sigmatcp.service
        if [ -d $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants ]; then \
          ln -fs ../../../../usr/lib/systemd/system/sigmatcp.service \
                  $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sigmatcp.service; \
        fi
endef

DSPTOOLKIT_POST_INSTALL_TARGET_HOOKS += DSPTOOLKIT_INSTALL_INIT

$(eval $(python-package))
$(eval $(python-host-package))
