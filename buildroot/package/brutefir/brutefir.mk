################################################################################
#
# brutefir
#
################################################################################

BRUTEFIR_VERSION = 62c1c1a32ebd855ca742513aae74f24a74bf49d2
BRUTEFIR_SITE = https://github.com/soundart/brutefir.git
BRUTEFIR_SITE_METHOD = git
BRUTEFIR_DEPENDENCIES =
BRUTEFIR_LICENSE = GPL-2.0
BRUTEFIR_LICENSE_FILES = LICENSE


define BRUTEFIR_INSTALL_EXTRA_FILES
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/brutefir/brutefir_mpd_config \
		$(TARGET_DIR)/etc/brutefir_mpd_config
endef

BRUTEFIR_POST_INSTALL_TARGET_HOOKS += BRUTEFIR_INSTALL_EXTRA_FILES

$(eval $(cmake-package))
