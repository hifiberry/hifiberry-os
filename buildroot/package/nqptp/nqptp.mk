################################################################################
#
# nqptp
#
################################################################################

NQPTP_VERSION = 591f425d9da69f1c4e09f3ad09611b758937b3e5
NQPTP_SITE = $(call github,mikebrady,nqptp,$(NQPTP_VERSION))

# git clone, no configure
NQPTP_AUTORECONF = YES

define NQPTP_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/nqptp/nqptp.service \
                $(TARGET_DIR)/usr/lib/systemd/system/nqptp.service
endef

$(eval $(autotools-package))
