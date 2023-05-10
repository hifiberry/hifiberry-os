# Known problems

* Spotifyd sometimes crashes. This seems to happen only when it is not active. It will be automatically restarted, but you might still notice that it's not available in the Spotify client
* Bluetooth volume control does not affect ALSA master volume, but is handled internally. This means, increasing/decreasing 
volume on Bluetooth won't have any effect on other applications.
This is a limitation of the Bluetooth ALSA software
* Bluetooth initialisation doesn't work 100% reliable. In case Bluetooth isn't starting up, try rebooting.
