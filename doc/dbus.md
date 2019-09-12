# DBUS examples

## MPRIS

dbus-send ---system -print-reply --type=method_call --dest=org.mpris.MediaPlayer2.spotifyd /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause

## Bluetooth

dbus-send --system --print-reply --dest=org.bluez /org/bluez/hci0/dev_77_88_99_11_22_33 org.bluez.MediaControl1.Pause
dbus-send --system --print-reply --dest=org.bluez /org/bluez/hci0/dev_77_88_99_11_22_33 org.bluez.MediaControl1.Play
