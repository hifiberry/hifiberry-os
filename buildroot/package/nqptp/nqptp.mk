################################################################################
#
# nqptp
#
################################################################################

NQPTP_VERSION = 2ffa47e018c9d68a7817148fc42c6074e0b00823
NQPTP_SITE = $(call github,hifiberry,nqptp,$(NQPTP_VERSION))

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
