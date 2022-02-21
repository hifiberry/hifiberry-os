################################################################################
#
# nqptp
#
################################################################################

NQPTP_VERSION = 4df1dee820e97f1307e745f5e2107736b7df8feb
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
