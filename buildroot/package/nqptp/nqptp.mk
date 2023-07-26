################################################################################
#
# nqptp
#
################################################################################

NQPTP_VERSION = 57fc7ac20ffd7a04ea5fbed6417e4c658bb7eb68
NQPTP_SITE = $(call github,mikebrady,nqptp,$(NQPTP_VERSION))

# git clone, no configure
NQPTP_AUTORECONF = YES

define NQPTP_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/nqptp/nqptp.service \
                $(TARGET_DIR)/usr/lib/systemd/system/nqptp.service
endef

$(eval $(autotools-package))
