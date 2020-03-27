################################################################################
#
# python-youtube-dl
#
################################################################################

PYTHON_YOUTUBE_DL_VERSION = 2020.3.8
PYTHON_YOUTUBE_DL_SOURCE = youtube_dl-$(PYTHON_YOUTUBE_DL_VERSION).tar.gz
PYTHON_YOUTUBE_DL_SITE = https://files.pythonhosted.org/packages/15/2a/7f7699a3655762eb881dd451603e02f95ab6fffb983ad430c0a42d8740e7
PYTHON_YOUTUBE_DL_SETUP_TYPE = setuptools
PYTHON_YOUTUBE_DL_LICENSE = Public Domain
PYTHON_YOUTUBE_DL_LICENSE_FILES = LICENSE

$(eval $(python-package))
