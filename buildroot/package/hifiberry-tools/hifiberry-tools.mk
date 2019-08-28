################################################################################
#
# hifiberry-tools
#
################################################################################

HIFIBERRY_TOOLS_VERSION = master
HIFIBERRY_TOOLS_LICENSE = MIT
HIFIBERRY_TOOLS_SITE = $(call github,hifiberry,hifiberry-tools,master)

define HIFIBERRY_TOOLS_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/detect-hifiberry \
           $(TARGET_DIR)/opt/hifiberry/bin/detect-hifiberry
    $(INSTALL) -D -m 0755 $(@D)/reconfigure-players \
           $(TARGET_DIR)/opt/hifiberry/bin/reconfigure-players
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/check-daemons \
           $(TARGET_DIR)/opt/hifiberry/bin/check-daemons
    $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/config-files \
           $(TARGET_DIR)/opt/hifiberry/etc/config-files
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/save-config \
           $(TARGET_DIR)/opt/hifiberry/bin/save-config
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/restore-config \
           $(TARGET_DIR)/opt/hifiberry/bin/restore-config
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/myip \
           $(TARGET_DIR)/opt/hifiberry/bin/myip

    for a in $(@D)/conf/asound.conf.*; do \
      $(INSTALL) -D -m 0644 $$a \
            $(TARGET_DIR)/etc ; \
    done
    $(INSTALL) -D -m 0644 $(@D)/conf/asound.conf.dmix_softvol \
           $(TARGET_DIR)/etc/asound.conf
    [ -d $(TARGET_DIR)/boot ] || mkdir $(TARGET_DIR)/boot
endef

define HIFIBERRY_TOOLS_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/S98hifiberry-detect \
                $(TARGET_DIR)/etc/init.d/S98hifiberry-detect
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/S99x-myip \
                $(TARGET_DIR)/etc/init.d/S99x-myip
endef

define HIFIBERRY_TOOLS_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry-detect.service \
                $(TARGET_DIR)/lib/systemd/system/hifiberry-detect.service
        ln -fs ../../../usr/lib/systemd/system/hifiberry-detect.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/hifiberry-detect.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/configure-players.service \
                $(TARGET_DIR)/lib/systemd/system/configure-players.service
        ln -fs ../../../usr/lib/systemd/system/configure-players.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/configure-players.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/myip.service \
                $(TARGET_DIR)/lib/systemd/system/myip.service
        ln -fs ../../../usr/lib/systemd/system/myip.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/myip.service
endef



$(eval $(generic-package))
