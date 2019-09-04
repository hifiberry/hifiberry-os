# MPRIS

There are several player applications running concurrently on HiFiBerryOS. That makes controlling all of 
them quite complex. Ideally a single interface should be used for all players. A good candidate is DBUS MPRIS.

However, today not all applications support MPRIS. This is the current state of MPRIS implementations:

| Player | MPRIS supported | MPRIS metadata | Potential alternative |
| --- | --- | --- | --- |
| spotifyd | yes | yes | - |
| shairport-sync  | yes | yes | - |
| squeezelite | no | no | [slimpris](https://github.com/mavit/slimpris2) |
| bluez-alsa | no | no | - |
| raat | no | no | - |
| mpd | no | no | [mpd mpris](https://github.com/natsukagami/mpd-mpris) |
