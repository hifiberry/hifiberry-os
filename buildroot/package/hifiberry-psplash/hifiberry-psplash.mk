################################################################################
#
# hifiberry-psplash
#
################################################################################

HIFIBERRY_PSPLASH_SOURCE = psplash-2015f7073e98dd9562db0936a254af5ef56356cf.tar.gz
HIFIBERRY_PSPLASH_SITE = http://git.yoctoproject.org/cgit/cgit.cgi/psplash/snapshot
HIFIBERRY_PSPLASH_LICENSE = GPL-2.0+
HIFIBERRY_PSPLASH_LICENSE_FILES = COPYING
HIFIBERRY_PSPLASH_AUTORECONF = YES

define HIFIBERRY_PSPLASH_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 package/psplash/psplash-start.service \
		$(TARGET_DIR)/usr/lib/systemd/system/psplash-start.service
	$(INSTALL) -d $(TARGET_DIR)/etc/systemd/system/sysinit.target.wants
	ln -sf  ../../../../usr/lib/systemd/system/psplash-start.service \
		$(TARGET_DIR)/etc/systemd/system/sysinit.target.wants/

	$(INSTALL) -D -m 644 package/psplash/psplash-quit.service \
		$(TARGET_DIR)/usr/lib/systemd/system/psplash-quit.service
	$(INSTALL) -d $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
	ln -sf  ../../../../usr/lib/systemd/system/psplash-quit.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/
endef

define HIFIBERRY_PSPLASH_CHANGE_IMAGE
	cp $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-psplash/*.h $(@D)
endef

HIFIBERRY_PSPLASH_PRE_CONFIGURE_HOOKS += HIFIBERRY_PSPLASH_CHANGE_IMAGE

$(eval $(autotools-package))
