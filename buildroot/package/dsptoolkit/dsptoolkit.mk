################################################################################
#
# dsptoolkit
#
################################################################################

DSPTOOLKIT_VERSION = 0.12.1
DSPTOOLKIT_SOURCE = hifiberrydsp-$(DSPTOOLKIT_VERSION).tar.gz
DSPTOOLKIT_SITE = https://files.pythonhosted.org/packages/e9/fc/5844905eabfe5640bdb33716f376f70beb131853fcbb2866a2ec2c177527
DSPTOOLKIT_SETUP_TYPE = setuptools
DSPTOOLKIT_LICENSE = MIT
DSPTOOLKIT_LICENSE_FILES = LICENSE.md

define DSPTOOLKIT_POST_INSTALL_STAGING_CMD
	[ -d $(TARGET_DIR)/opt/hifiberry/contrib ] || mkdir $(TARGET_DIR)/opt/hifiberry/contrib
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/4way-iir.xml
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/dspdac.txt
           $(TARGET_DIR)/opt/hifiberry/contrib
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/muted.txt
           $(TARGET_DIR)/opt/hifiberry/contrib

endef

DSPTOOLKIT_POST_INSTALL_STAGING_HOOKS += DSPTOOLKIT_POST_INSTALL_STAGING_CMD

define DSPTOOLKIT_INSTALL_INIT_SYSV
	pwd
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/S90sigmatcp \
		$(TARGET_DIR)/etc/init.d/S90sigmatcp
endef

define DSPTOOLKIT_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/sigmatcp.service \
                $(TARGET_DIR)/lib/systemd/system/sigmatcp.service
endef

DSPTOOLKIT_POST_INSTALL_STAGING_HOOKS += DSPTOOLKIT_INSTALL_INIT_SYSV

$(eval $(python-package))
