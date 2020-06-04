# HiFiBerryOS build system

HiFiBerryOS is based on Buildroot and uses its build system. There are some additional tools that should simplify 
working with buildroot

## Directory structure

HiFiBerryOS resides outside the buildroot sources. That allows to easily upgrade one of both without affecting 
the other one. Both buildroot and HifiberryOS need to share the same parent directory, e.g.

/build/hifiberryos
/build/buildroot

This is necessary as all HiFiBerryOS packages uses relative paths when referring to buildroot packages.

Please make sure you have 20+GB disk space for each hardware version being built.

### configs

All config files reside here

### images

The final SD card images will be created in this folder

### buildroot

Contains the source of all HiFiBerryOS specific packages that are not included already in the normal
buildroot software.


## Scripts

When building HiFiBerryOS, you should change to the HiFiBerryOS directory first.

### clean
 
Cleans up the buildroot folder. When using this, you have to rebuild the whole system. This can take a long time. 
Therefore, it is recommended to only use this when changing to another processor architrecture or something is completely
messed up.

### build-config

Creates a HiFiBerryOS configuration for the given Raspberry Pi platform, e.g.

`build-config 3` creates the default configuration for the Raspberry Pi 3

## config

Starts the configuration interface. Here you can add/remove packages or change other parameters.

## compile

Compiles a full HiFiBerryOS version. When building from scratch, this can take a long time (2 hours even on an up-to-date PC).

Sometimes, you want to rebuild only a specific module. Especially when changing some sources, buildroot often doesn't notice 
this and therefore doesn't rebuild the package. To deal with this you can add a parameter to compile.sh to rebuild specific 
packages, e.g. 

`./compile 3 spotify` will rebuild the spotify package
`./compile 4 hifiberry` will rebuild all packages with names starting with hifiberry

## create-image

Creates the image and update files for a specific Raspberry Pi hardware. Parameter is the Pi version, e.g. 0w, 3 or 4.

## update-pi

Creates an image from the latest compile run and pushes it to the Raspberry Pi given as a command line parameter.
To make sure this works, the version of Raspberry Pi must match the version that you compiled the image for. Also, the updater expects that the Pi is still using the default password, though you can override this.

`./update-pi {VERSION} {HOST_IP} {PORT=22} {PASSWORD=hifiberry}`

You will also need to have `sshpass` installed, make sure to add the host keys for each new Pi to your known hosts file before beginning an update, e.g.

`ssh-keyscan raspberrypi-ip >> ~/.ssh/known_hosts`

## build-all

Starts a release build that will build images for all supported Raspberry Pi platforms. This will definitely 
take several hours, it should only be used when packaging a new release.

# Known problems

WPE_webkit might fail to build if you don't have enough RAM. In this case, reduce the number jobs to run simultaneously. If set to 0 it will use number of threads + 1, you might set this to a lower number. 
