# HiFiBerryOS configuration

There are very few configuration option on HiFiBerryOS as the system will automatically configure the 
correct settings for your HiFiBerry sound card.

## Root password

The default root password is "hifiberry". As SSH is enabled by default, we *strongly* recommend to login and 
set a new root password. Just login and run the command

    passwd

## System name

The default system name is "HiFiBerry". It will be used to identify the system. To change this settings, login to
the system and edit /etc/systemname, then run

    /opt/hifiberry/bin/reconfigure-players 
    
or just reboot. 
