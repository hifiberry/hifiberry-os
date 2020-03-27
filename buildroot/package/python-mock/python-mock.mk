################################################################################
#
# python-mock
#
################################################################################

PYTHON_MOCK_VERSION = 4.0.2
PYTHON_MOCK_SOURCE = mock-$(PYTHON_MOCK_VERSION).tar.gz
PYTHON_MOCK_SITE = https://files.pythonhosted.org/packages/2e/35/594f501b2a0fb3732c8190ca885dfdf60af72d678cd5fa8169c358717567
PYTHON_MOCK_SETUP_TYPE = setuptools

$(eval $(python-package))
