################################################################################
#
# python-wisa
#
################################################################################

define PYTHON_WISA_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/python-wisa/pysummit-3.3.1-py3.8.egg \
                $(TARGET_DIR)/usr/lib/python3.9/site-packages
	echo "./pysummit-3.3.1-py3.8.egg" >> $(TARGET_DIR)/usr/lib/python3.9/site-packages/easy_install.pth
endef

$(eval $(generic-package))
