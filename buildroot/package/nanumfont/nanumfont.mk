NANUMFONT_VERSION = 2.5
NANUMFONT_SITE = https://github.com/naver/nanumfont/releases/download/VER$(NANUMFONT_VERSION)
NANUMFONT_SOURCE = NanumGothicCoding-$(NANUMFONT_VERSION).zip
NANUMFONT_SITE_METHOD = wget

# Define extraction directory
NANUMFONT_EXTRACT_DIR = $(BUILD_DIR)/nanumfont-$(NANUMFONT_VERSION)

define NANUMFONT_EXTRACT_CMDS
	unzip $(DL_DIR)/nanumfont/$(NANUMFONT_SOURCE) -d $(@D)
endef

define NANUMFONT_BUILD_CMDS
	# No build commands required
endef

define NANUMFONT_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/share/fonts/NanumFont
	cp -r $(NANUMFONT_EXTRACT_DIR)/* $(TARGET_DIR)/usr/share/fonts/NanumFont
	ls -lR $(TARGET_DIR)/usr/share/fonts/NanumFont
endef

$(eval $(generic-package))
