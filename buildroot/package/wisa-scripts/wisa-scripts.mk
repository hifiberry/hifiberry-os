################################################################################
#
# wisa-scripts
#
################################################################################

#WISA_SCRIPTS_VERSION =  1967d6a40f3ce6341c1bff4339bb4fa5af56495d
#WISA_SCRIPTS_SITE = $(call github,j-schambacher,kad-scripts,$(WISA_SCRIPTS_VERSION))

define WISA_SCRIPTS_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/opt/wisa
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/stereo_start.py \
                $(TARGET_DIR)/opt/wisa/bin/stereo_start.py
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/system_startup.py \
                $(TARGET_DIR)/opt/wisa/bin/system_startup.py
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/system_shutdown.py \
                $(TARGET_DIR)/opt/wisa/bin/system_shutdown.py
        $(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/tx_start.py \
                $(TARGET_DIR)/opt/wisa/bin/tx_start.py

	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/conf/mono.cfg \
		$(TARGET_DIR)/opt/wisa/etc/mono.cfg.example
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/conf/stereo.cfg \
		$(TARGET_DIR)/opt/wisa/etc/stereo.cfg.example
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/conf/stereo.cfg \
                $(TARGET_DIR)/opt/wisa/etc/room.cfg
endef


define WISA_SCRIPTS_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/wisa-scripts/wisa.service \
                $(TARGET_DIR)/usr/lib/systemd/system/wisa.service
endef

$(eval $(generic-package))
