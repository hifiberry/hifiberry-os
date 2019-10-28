# HiFiBerryOS initial configuration

There is now one main configuration file named *hifiberry.conf*. It can reside either on the FAT partition of the SD card 
or in /etc. If both files exists, the file on the FAT partition will be used.

The behaviour has changed with the HiFiBerryOS release October 2019. Previously the configuration file was always used. Now it is used only once and will be automatically removed. The configuration file is only to be used for initial configuration
now. We recommend to use it only, if you need to install a large amount of systems. Setting up a single system is easier using the GUI that's included since release 20191029.

## General 

HiFiBerryOS will work without any special configuration. If you connect the Raspberry Pi to your local Ethernet network (that should support DHCP)
and boot HiFiBerryOS, the system will provide the services without any additional configuration. However, some services allow additional configuration.

Some service can be enabled or disabled. This can be controlled by setting the xxxx_enable setting to 0 or 1. Note that only 0 and
1 are supported here.
By default, all services are enabed (except WiFi that requires an additional configuration).

## System configuration
```
system_name="HiFiBerry"
```

This sets the system name. It can contain spaces, but for some services that do not support spaces, these will be converted
into dashes. Note that you should not use any special characters as not all services might be able to handle these.

## WiFi
```
wifi_ssid=homenetwork
wifi_psk=mypassphrase
wifi_country=DE
wifi_enable=1
```

Set SSID, passphrase and country to use WiFi. Country needs to be the 2 character country code of the country the device
is operated. This is needed to select the correct WiFi channels that can be different in different countries.

## Spotify
```
spotify_enable=1
spotify_user=myuser
spotify_password=mypass
```

Spotify is enabled by default. It will also work without setting a username and password. In our experience it makes sense
to set these if you have a lot of Spotify-enabled systems running in your network as sometimes Spotify connect won't list all
of them.


## Airplay
```
airplay_enable=1
```

Enables/disables Airplay support

## Roon
```
roon_enable=1
```

Enables/disables ROON support.
Note that Roon is not supported on the Raspberry Pi Zero.


## Squeezebox 
```
squeezebox_enable=1
```

Enables/disables Squeezebox support

## Bluetooth
```
bluetooth_enable=1
```

Enables/disables Bluetooth support
