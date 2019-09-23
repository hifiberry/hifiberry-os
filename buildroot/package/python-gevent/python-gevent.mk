################################################################################
#
# python-gevent
#
################################################################################

PYTHON_GEVENT_FILE = gevent-1.4.0-cp37-cp37m-linux_armv7l.whl
PYTHON_GEVENT_EXTRA_DOWNLOADS=https://www.piwheels.org/simple/gevent/$(PYTHON_GEVENT_FILE)


define PYTHON_GEVENT_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/usr/lib/python3.7/site-packages
	cd $(TARGET_DIR)/usr/lib/python3.7/site-packages ; \
          unzip -x -o $(PYTHON_GEVENT_DL_DIR)/$(PYTHON_GEVENT_FILE)
endef

$(eval $(generic-package))
