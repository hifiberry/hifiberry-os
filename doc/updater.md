# Updater process

One design goal was robustness. As we want users to regularly update their systems, it is very important to make
sure the system won't break during an update. 

We use two OS images on two separate partitions on the SD card. The layout is as follows:

p0 | fat | /boot
p1 | ext4 | root 1
p2 | ext4 | root 2
p3 | ext4 | /data

All user data (e.g. a local music library) should be stored on the /data partition as the root file system partitions will
be overwritten during an system upgrade.

The upgrade process is as follows:
- check latest version on web server, if new version is available download it to /data
- identify inactive root partition, extract update to this partition
- extract kernel to /boot
- adapt cmdline.txt to use the new root partition
- reboot
