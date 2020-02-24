################################################################################
#
# python-tzupdate
#
################################################################################

PYTHON_TZUPDATE_VERSION = 2.0.0
PYTHON_TZUPDATE_SOURCE = tzupdate-$(PYTHON_TZUPDATE_VERSION).tar.gz
PYTHON_TZUPDATE_SITE = https://files.pythonhosted.org/packages/ca/07/30e7e5877c441ed3c779fd776c33185caafbc9faddfb3c53707bb5187f93
PYTHON_TZUPDATE_SETUP_TYPE = setuptools
PYTHON_TZUPDATE_LICENSE = Public Domain
PYTHON_TZUPDATE_LICENSE_FILES = LICENSE

define PYTHON_TZUPDATE_INSTALL_INIT
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/python-tzupdate/tzupdate.service \
               $(TARGET_DIR)/usr/lib/systemd/system/tzupdate.service
        if [ -d $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants ]; then \
		ln -fs ../../../../usr/lib/systemd/system/tzupdate.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/tzupdate.service; \
	fi
endef

PYTHON_TZUPDATE_POST_INSTALL_TARGET_HOOKS += PYTHON_TZUPDATE_INSTALL_INIT


$(eval $(python-package))
