# MPRIS

There are several player applications running concurrently on HiFiBerryOS. That makes controlling all of 
them quite complex. We're using MPRIS.

Today not all applications support MPRIS. This is the current state of MPRIS implementations:

| Player | MPRIS supported | MPRIS metadata |  Implemented
| --- | --- | --- |  --- |
| spotifyd | yes | yes |  yes |
| shairport-sync  | yes | yes |  yes |
| squeezelite | via [lmsmpris](https://github.com/hifiberry/lmsmpris) | yes | yes |
| bluez-alsa | via [mpris-proxy](https://github.com/Vudentz/BlueZ/blob/master/tools/mpris-proxy.c) | yes | yes | 
| raat | yes | yes | yes |
| mpd | via [mpd mpris](https://github.com/natsukagami/mpd-mpris) | yes | yes |
| alsaloop | no | no | no |
