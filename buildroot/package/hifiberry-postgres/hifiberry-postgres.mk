################################################################################
#
# hifiberry-postgres
#
################################################################################

define HIFIBERRY_POSTGRES_INSTALL_TARGET_CMDS
        $(INSTALL) -D -m 0555 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-postgres/create-hbdb \
                $(TARGET_DIR)/opt/hifiberry/helpers/create-hbdb
endef

define HIFIBERRY_POSTGRES_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-postgres/postgresql.service \
                $(TARGET_DIR)/usr/lib/systemd/system/postgresql.service
endef

$(eval $(generic-package))
