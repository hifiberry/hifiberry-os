################################################################################
#
# raat
#
################################################################################

RAAT_VERSION = master
RAAT_SITE = file:///tmp/raat

define RAAT_BUILD_CMDS
	$(MAKE) TARGET=linux-rpi2
endef

$(eval $(generic-package))
