# Known problems

* WiFi initialisation is very slow (can take up to 1min)
* Bluetooth volume control does not affect ALSA master volume, but is handled internally. This measn, increasing/decreasing 
volume on Bluetooth won't have any effect on other applications.
This is a limitation of the Bluetooth ALSA software
