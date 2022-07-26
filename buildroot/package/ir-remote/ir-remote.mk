################################################################################
#
# ir-remote
#
################################################################################

IR_REMOTE_INSTALL_TARGET = YES
IR_REMOTE_DEPENDENCIES = libv4l

define IR_REMOTE_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/ir-remote/keymap.toml \
                $(TARGET_DIR)/etc/rc_keymaps/keymap.toml
    $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/ir-remote/ir.service \
                $(TARGET_DIR)/lib/systemd/system/ir.service
endef

$(eval $(generic-package))
