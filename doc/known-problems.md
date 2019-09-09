# Known problems

* Bluetooth volume control does not affect ALSA master volume, but is handled internally. This measn, increasing/decreasing 
volume on Bluetooth won't have any effect on other applications.
This is a limitation of the Bluetooth ALSA software
* Bluetooth initialisation doesn't work 100% reliable. In case Bluetooth isn't starting up, try rebooting.
