# HiFIBerryOS Extensions

## Introduction

Extenions are programs that extend the functionality of the HiFiBerryOS core system. 

They consist of
- docker containers
- Beocreate extension code

Both are optional. This means an extension can just run some code in a container without
any user interface code or implement just some user interface without running additional 
code.

## Running extensions

Extensions will be downloaded from the internet. Therefore, an internet connection is 
required to use any extensions. It is recommended to boot the system initally with Ethernet 
connected on a DHCP network with Interbnet connectivity. This will allow HiFiBerryOS to
download, configrue and start the default extensions

## /etc/extensions.conf

This is the main configuration file that contains the date for all extensions.
This file is managed by HiFIBerryOS. Do not edit it, as it will be overwritten by updates.

## Current state (3.4.24)
| Name      | Player      | Metadata       | Control     | is-active|Stop Other Players |
|-----------|-------------|----------------|-------------|----------|-------------------|
|shairport|yes|yes|yes|yes|yes|
|raat|yes|yes|yes|-|yes|
|spotifyd|untested|untested|untested|untested|
|squeezelite|untested|untested|untested|untested|
|snapcast|untested|untested|untested|untested|
|plexamp|untested|untested|untested|untested|
|lms|no|no|no|no|
|ympd|no|no|no|no|
