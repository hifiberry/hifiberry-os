################################################################################
#
# nqptp
#
################################################################################

NQPTP_VERSION = b7130951e0be69a62651347e4cccecf7d106e648
NQPTP_SITE = $(call github,mikebrady,nqptp,$(NQPTP_VERSION))

# git clone, no configure
NQPTP_AUTORECONF = YES
#NQPTP_INSTALL_TARGET = NO

#define NQPTP_INSTALL_TARGET
#	sleep 100
#	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/nqptp/nqptp.service \
#	  	$(TARGET_DIR)/usr/lib/systemd/system/nqptp.service
#endef

#define NQPTP_INSTALL_INIT_SYSTEMD
#        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/nqptp/nqptp.service \
#                $(TARGET_DIR)/usr/lib/systemd/system/nqptp.service
#endef

$(eval $(autotools-package))
