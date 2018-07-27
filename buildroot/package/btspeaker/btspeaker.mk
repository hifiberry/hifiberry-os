################################################################################
#
# btspeaker
#
################################################################################

BTSPEAKER_VERSION = master
BTSPEAKER_SITE = $(call github,lukasjapan,bt-speaker,master)

BTSPEAKER_DEPENDENCIES = 

define BTSPEAKER_BUILD_CMDS
endef

define BTSPEAKER_INSTALL_TARGET_CMDS
    [ -d $(TARGET_DIR)/btspeaker ] || mkdir -p $(TARGET_DIR)/btspeaker 
    $(INSTALL) -D -m 0755 $(@D)/bt_speaker.py \
           $(TARGET_DIR)/opt/btspeaker/bt_speaker.py
    $(INSTALL) -D -m 0644 $(@D)/librtpsbc.so\
           $(TARGET_DIR)/opt/btspeaker/
    cp -rv $(@D)/bt_manager $(TARGET_DIR)/opt/btspeaker/
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/config.ini \
           $(TARGET_DIR)/etc/bt_speaker/config.ini
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/connect \
           $(TARGET_DIR)/etc/bt_speaker/hooks/connect
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/btspeaker/disconnect \
           $(TARGET_DIR)/etc/bt_speaker/hooks/disconnect
endef

define BTSPEAKER_INSTALL_INIT_SYSV
endef

define DSPTOOLKIT_INSTALL_INIT_SYSTEMD
endef

$(eval $(generic-package))
