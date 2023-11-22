################################################################################
#
# dsptoolkit
#
################################################################################

DSPTOOLKIT_VERSION = 2040fb0cbc6fc85715b913fcbda7c46296da5ecd
DSPTOOLKIT_SITE = $(call github,hifiberry,hifiberry-dsp,$(DSPTOOLKIT_VERSION))
DSPTOOLKIT_SETUP_TYPE = setuptools
DSPTOOLKIT_LICENSE = MIT
DSPTOOLKIT_LICENSE_FILES = LICENSE.md

define DSPTOOLKIT_POST_INSTALL_TARGET_CMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/sigmatcp.conf \
				$(TARGET_DIR)/etc/sigmatcp.conf
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/dump-spdif-status.sh \
				$(TARGET_DIR)/opt/hifiberry/bin/dump-spdif-status
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/spdif2pi \
				$(TARGET_DIR)/opt/hifiberry/bin/spdif2pi
endef

DSPTOOLKIT_POST_INSTALL_TARGET_HOOKS += DSPTOOLKIT_POST_INSTALL_TARGET_CMD

define DSPTOOLKIT_INSTALL_INIT
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/S90sigmatcp \
		$(TARGET_DIR)/etc/init.d/S90sigmatcp
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/sigmatcp.service \
                $(TARGET_DIR)/usr/lib/systemd/system/sigmatcp.service
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/dspvolume.ctl \
		$(TARGET_DIR)/etc/dspvolume.ctl
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/create-dspvolume \
		$(TARGET_DIR)/opt/hifiberry/bin/create-dspvolume
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/dsptoolkit/spdifclockgen.service \
		$(TARGET_DIR)/usr/lib/systemd/system/spdifclockgen.service
#	echo "disable spdifclockgen.service" >> $(TARGET_DIR)/lib/systemd/system-preset/99-spdifclockgen.preset
endef

DSPTOOLKIT_POST_INSTALL_TARGET_HOOKS += DSPTOOLKIT_INSTALL_INIT

$(eval $(python-package))
$(eval $(python-host-package))
