################################################################################
#
# hifiberry-tools
#
################################################################################

ASOUNDCONF = asound.conf.exclusive

define HIFIBERRY_TOOLS_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/bootmsg \
           $(TARGET_DIR)/opt/hifiberry/bin/bootmsg
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/detect-hifiberry \
           $(TARGET_DIR)/opt/hifiberry/bin/detect-hifiberry
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/reconfigure-players \
           $(TARGET_DIR)/opt/hifiberry/bin/reconfigure-players
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/check-daemons \
           $(TARGET_DIR)/opt/hifiberry/bin/check-daemons
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/check-compatibility \
           $(TARGET_DIR)/opt/hifiberry/bin/check-compatibility
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/pause-all \
           $(TARGET_DIR)/opt/hifiberry/bin/pause-all
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/myip \
           $(TARGET_DIR)/opt/hifiberry/bin/myip
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/myurl \
           $(TARGET_DIR)/opt/hifiberry/bin/myurl
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/debuginfo \
           $(TARGET_DIR)/opt/hifiberry/bin/debuginfo
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/alsa-mode \
           $(TARGET_DIR)/opt/hifiberry/bin/alsa-mode
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/sshdconfig \
           $(TARGET_DIR)/opt/hifiberry/bin/sshdconfig
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry-cardid \
           $(TARGET_DIR)/opt/hifiberry/bin/hifiberry-cardid
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/fix-dacadcpro-mixer \
	   $(TARGET_DIR)/opt/hifiberry/bin/fix-dacadcpro-mixer
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/set-initial-volume \
           $(TARGET_DIR)/opt/hifiberry/bin/set-initial-volume
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/stop-all-players \
           $(TARGET_DIR)/opt/hifiberry/bin/stop-all-players
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/store-volume \
           $(TARGET_DIR)/opt/hifiberry/bin/store-volume
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/restore-volume \
           $(TARGET_DIR)/opt/hifiberry/bin/restore-volume
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/speaker-role \
	   $(TARGET_DIR)/opt/hifiberry/bin/speaker-role
    $(INSTALL) -D -m 0600 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry.conf.sample \
           $(TARGET_DIR)/etc/hifiberry.conf.sample
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/resize-partitions \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/activate-data-partition \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/check-system \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/unmute-amp100 \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/readhat \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/reset-amp100 \
		$(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/alsa-state \
		$(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/enable-updi \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/enable-mdns \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/shutdown-system \
		$(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/set-host-ip \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/fix-unused-volume \
		$(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/check-internet.py \
                $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/check-network.sh \
	        $(TARGET_DIR)/opt/hifiberry/bin
    $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/snd_soc_core_disable_pm.conf \
		$(TARGET_DIR)/etc/modprobe.d/snd_soc_core_disable_pm.conf
    touch $(TARGET_DIR)/resize-me
    touch $(TARGET_DIR)/etc/spotifyd.conf

    # disable sshd by default
    if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
       rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
    fi

    touch $(TARGET_DIR)/etc/force_exclusive_audio

    for a in $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/conf/asound.conf.*; do \
      $(INSTALL) -D -m 0644 $$a \
            $(TARGET_DIR)/etc ; \
    done
    echo Using $(ASOUNDCONF)
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/conf/$(ASOUNDCONF) \
           $(TARGET_DIR)/etc/asound.conf
    [ -d $(TARGET_DIR)/boot ] || mkdir $(TARGET_DIR)/boot
endef

define HIFIBERRY_TOOLS_INSTALL_INIT_SYSV
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/S60initial-volume \
                $(TARGET_DIR)/etc/init.d/S60initial-volume
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/S98hifiberry-detect \
                $(TARGET_DIR)/etc/init.d/S98hifiberry-detect
endef

define HIFIBERRY_TOOLS_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry-detect.service \
                $(TARGET_DIR)/lib/systemd/system/hifiberry-detect.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/configure-players.service \
                $(TARGET_DIR)/lib/systemd/system/configure-players.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/myip.service \
                $(TARGET_DIR)/lib/systemd/system/myip.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/resize-partitions.service \
                $(TARGET_DIR)/usr/lib/systemd/system/resize-partitions.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/reboot.service \
                $(TARGET_DIR)/usr/lib/systemd/system/reboot.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/activate-data-partition.service \
                $(TARGET_DIR)/usr/lib/systemd/system/activate-data-partition.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/restore-volume.service \
                $(TARGET_DIR)/usr/lib/systemd/system/restore-volume.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/store-volume.service \
                $(TARGET_DIR)/usr/lib/systemd/system/store-volume.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/store-volume.timer \
                $(TARGET_DIR)/usr/lib/systemd/system/store-volume.timer
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry.target \
                $(TARGET_DIR)/usr/lib/systemd/system/hifiberry.target
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/hifiberry-finish.service \
                $(TARGET_DIR)/usr/lib/systemd/system/hifiberry-finish.service
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/sshdconfig.service \
                $(TARGET_DIR)/usr/lib/systemd/system/sshdconfig.service
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/internet.service \
                $(TARGET_DIR)/usr/lib/systemd/system/internet.service
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/network-up.service \
		$(TARGET_DIR)/usr/lib/systemd/system/network-up.service

	# Systemd logging to RAM
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-tools/journald.conf \
	        $(TARGET_DIR)/etc/systemd/journald.conf
endef

$(eval $(generic-package))
