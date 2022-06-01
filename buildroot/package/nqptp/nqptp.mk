################################################################################
#
# nqptp
#
################################################################################

NQPTP_VERSION = 44e74cc0870820d73d238c28380135f98d895348
NQPTP_SITE = $(call github,mikebrady,nqptp,$(NQPTP_VERSION))

# git clone, no configure
NQPTP_AUTORECONF = YES

define NQPTP_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/nqptp/nqptp.service \
                $(TARGET_DIR)/usr/lib/systemd/system/nqptp.service
endef

$(eval $(autotools-package))
