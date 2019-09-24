################################################################################
#
# hifiberry-tools
#
################################################################################

define HIFIBERRY_TOOLS_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/detect-hifiberry \
           $(TARGET_DIR)/opt/hifiberry/bin/detect-hifiberry
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/reconfigure-players \
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
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/set-initial-volume \
           $(TARGET_DIR)/opt/hifiberry/bin/set-initial-volume
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/configure-system \
           $(TARGET_DIR)/opt/hifiberry/bin/configure-system
    $(INSTALL) -D -m 0600 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry.conf.sample \
           $(TARGET_DIR)/etc/hifiberry.conf.sample
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/resize-partitions \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/activate-data-partition \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0444 $(BR2_EXTERNAL_HIFIBERRY_PATH)/PIVERSION \
                $(TARGET_DIR)/etc/PIVERSION
    touch $(TARGET_DIR)/resize-me


    for a in $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/conf/asound.conf.*; do \
      $(INSTALL) -D -m 0644 $$a \
            $(TARGET_DIR)/etc ; \
    done
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/conf/asound.conf.dmix_softvol \
           $(TARGET_DIR)/etc/asound.conf
    [ -d $(TARGET_DIR)/boot ] || mkdir $(TARGET_DIR)/boot
endef

define HIFIBERRY_TOOLS_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/S60initial-volume \
                $(TARGET_DIR)/etc/init.d/S60initial-volume
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/S98hifiberry-detect \
                $(TARGET_DIR)/etc/init.d/S98hifiberry-detect
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/S99x-myip \
                $(TARGET_DIR)/etc/init.d/S99x-myip
endef

define HIFIBERRY_TOOLS_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry-detect.service \
                $(TARGET_DIR)/lib/systemd/system/hifiberry-detect.service
        ln -fs ../../../../usr/lib/systemd/system/hifiberry-detect.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/hifiberry-detect.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/configure-players.service \
                $(TARGET_DIR)/lib/systemd/system/configure-players.service
        ln -fs ../../../../usr/lib/systemd/system/configure-players.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/configure-players.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/myip.service \
                $(TARGET_DIR)/lib/systemd/system/myip.service
        ln -fs ../../../../usr/lib/systemd/system/myip.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/myip.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/initial-volume.service \
                $(TARGET_DIR)/lib/systemd/system/initial-volume.service
        ln -fs ../../../../usr/lib/systemd/system/initial-volume.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/initial-volume.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/configure-system.service \
                $(TARGET_DIR)/lib/systemd/system/configure-system.service
        ln -fs ../../../../usr/lib/systemd/system/configure-system.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/configure-system.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/resize-partitions.service \
                $(TARGET_DIR)/usr/lib/systemd/system/resize-partitions.service
        ln -fs ../../../../usr/lib/systemd/system/resize-partitions.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/resize-partitions.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/reboot.service \
                $(TARGET_DIR)/usr/lib/systemd/system/reboot.service
        ln -fs ../../../../usr/lib/systemd/system/reboot.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/reboot.service
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/activate-data-partition.service \
                $(TARGET_DIR)/usr/lib/systemd/system/activate-data-partition.service
        ln -fs ../../../../usr/lib/systemd/system/activate-data-partition.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/activate-data-partition.service
endef

$(eval $(generic-package))
