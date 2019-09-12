# MPRIS

There are several player applications running concurrently on HiFiBerryOS. That makes controlling all of 
them quite complex. Ideally a single interface should be used for all players. A good candidate is DBUS MPRIS.

However, today not all applications support MPRIS. This is the current state of MPRIS implementations:

| Player | MPRIS supported | MPRIS metadata |  Implemented
| --- | --- | --- |  --- |
| spotifyd | yes | yes |  yes |
| shairport-sync  | yes | yes |  yes |
| squeezelite | [slimpris](https://github.com/mavit/slimpris2) | no |  | no |
| bluez-alsa | via [mpris-proxy](https://github.com/Vudentz/BlueZ/blob/master/tools/mpris-proxy.c) | yes | - | yes |
| raat | partially | yes | - | yes |
| mpd | via [mpd mpris](https://github.com/natsukagami/mpd-mpris) | yes | yes |
| alsaloop | no | no | - | no |
