################################################################################
#
# hifiberry-alsaloop
#
################################################################################

HIFIBERRY_ALSALOOP_VERSION =  9c3adeccf60752c1df239be7ec6452c7443fddfb
HIFIBERRY_ALSALOOP_SITE = $(call github,hifiberry,alsaloop,$(HIFIBERRY_ALSALOOP_VERSION))

define SNAPCASTMPRIS_BUILD_CMDS
endef

define HIFIBERRY_ALSALOOP_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/alsaloop
	cp -rv $(@D)/* $(TARGET_DIR)/opt/alsaloop
endef


define HIFIBERRY_ALSALOOP_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-alsaloop/alsaloop.service \
                $(TARGET_DIR)/usr/lib/systemd/system/alsaloop.service
#        ln -fs ../../../../usr/lib/systemd/system/alsaloop.service \
#                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/alsaloop.service
endef

$(eval $(generic-package))
