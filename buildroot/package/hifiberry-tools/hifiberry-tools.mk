################################################################################
#
# hifiberry-tools
#
################################################################################

HIFIBERRY_TOOLS_VERSION = 0.1
HIFIBERRY_TOOLS_LICENSE = MIT
HIFIBERRY_TOOLS_SITE = $(call github,hifiberry,hifiberry-tools,master)

define HIFIBERRY_TOOLS_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/detect-hifiberry \
           $(TARGET_DIR)/opt/hifiberry/bin/detect-hifiberry
    for a in $(@D)/conf/asound.conf.*; do \
      $(INSTALL) -D -m 0644 $$a \
             $(TARGET_DIR)/etc ; \
    done
endef

$(eval $(generic-package))
