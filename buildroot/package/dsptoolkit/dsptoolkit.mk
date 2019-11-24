################################################################################
#
# dsptoolkit
#
################################################################################

DSPTOOLKIT_VERSION = 5a2688dbde8da75bdaf13a0be73f2f18acdd9f7d
DSPTOOLKIT_SITE = $(call github,hifiberry,hifiberry-dsp,$(DSPTOOLKIT_VERSION))
DSPTOOLKIT_SETUP_TYPE = setuptools
DSPTOOLKIT_LICENSE = MIT
DSPTOOLKIT_LICENSE_FILES = LICENSE.md

define DSPTOOLKIT_POST_INSTALL_STAGING_CMD
	echo "DSPTk 1"
        sleep 10
	[ -d $(TARGET_DIR)/opt/hifiberry/contrib ] || mkdir $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/4way-iir.xml
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/dspdac.txt
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/muted.txt
           $(TARGET_DIR)/opt/hifiberry/contrib

endef

DSPTOOLKIT_POST_INSTALL_STAGING_HOOKS += DSPTOOLKIT_POST_INSTALL_STAGING_CMD

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
