################################################################################
#
# python-levenshtein
#
################################################################################

PYTHON_LEVENSHTEIN_VERSION = 0.12.0
PYTHON_LEVENSHTEIN_SOURCE = python-Levenshtein-$(PYTHON_LEVENSHTEIN_VERSION).tar.gz
PYTHON_LEVENSHTEIN_SITE = https://files.pythonhosted.org/packages/42/a9/d1785c85ebf9b7dfacd08938dd028209c34a0ea3b1bcdb895208bd40a67d
PYTHON_LEVENSHTEIN_SETUP_TYPE = setuptools
PYTHON_LEVENSHTEIN_LICENSE = GNU General Public License v2 or later (GPLv2+)
PYTHON_LEVENSHTEIN_LICENSE_FILES = COPYING

$(eval $(python-package))
