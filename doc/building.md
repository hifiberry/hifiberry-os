# HiFiBerryOS build system

HiFiBerryOS is based on Buildroot and uses its build system. There are some additional tools that should simplify 
working with buildroot

## Directory structure

HiFiBerryOS resides outside the buildroot sources. That allows to easily upgrade one of both without affecting 
the other one. Both buildroot and HifiberryOS need to share the same parent directory, e.g.

/build/hifiberryos
/build/buildroot

This is necessary as all HiFiBerryOS packages uses relative paths when referring to buildroot packages.

### configs

All config files reside here

### images

The final SD card images will be created in this folder

### buildroot

Contains the source of all HiFiBerryOS specific packages that are not included already in the normal
buildroot software.


## Configuration files

TODO

## Scripts

When building HiFiBerryOS, you should change to the HiFiBerryOS directory first.

### clean.sh
 
Cleans up the buildroot folder. When using this, you have to rebuild the whole system. This can take a long time. 
Therefore, it is recommended to only use this when changing to another processor architrecture or something is completely
messed up.

### build-config.sh

Creates a HiFiBerryOS configuration for the given Raspberry Pi platform, e.g.

`build-config.sh 3` creates the default configuration for the Raspberry Pi 3

## config.sh

Starts the configuration interface. Here you can add/remove packages or change other parameters.

## compile.sh

Compiles a full HiFiBerryOS version. When building from scratch, this can take a long time (2 hours even on an up-to-date PC).

Sometimes, you want to rebuild only a specific module. Especially when changing some sources, buildroot often doesn't notice 
this and therefore doesn't rebuild the package. To deal with this you can add a parameter to compile.sh to rebuild specific 
packages, e.g. 

`./compile.sh spotify` will rebuild the spotify package
`./compile.sh hifiberry` will rebuild all packages with names starting with hifiberry

## create-image.sh

Creates the image and update files for a specific Raspberry Pi hardware. Parameter is the Pi version, e.g. 0w, 3 or 4.

## build-all.sh

Starts a release build that will build images for all supported Raspberry Pi platforms. This will definitely 
take several hours, it should only be used when packaging a new release.
