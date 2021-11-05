################################################################################
#
# hifiberry-users
#
################################################################################

# based on the original mpd package but with additional patches

define HIFIBERRY_USERS_USERS
    audio  2001 audio  2001 * - - - Audio hardware
    player 2002 player 2002 * - - - Music players
endef


$(eval $(generic-package))
