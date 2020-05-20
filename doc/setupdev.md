# Setting up the development environment

*Note:* The scripts are designed to work on Ubuntu. There is a good chance that they will also work on other Debian-based
systems. For other Linux distributions, you might have to adapt some of these scripts.

## Compilation environment

The system you're using should have at least 8GM RAM (more is better). Using a VM for the compilation works well. However, we can't recommend the Windows Subsystem for Linux due to it's poor I/O performance. As the build creates, reads and writes a huge amount of files, the build on WSL will be very slow.

In any case, expect a full build to take at least 50 minutes on a high-end system (>80 minutes for newer versions that include the local graphical interface) and much longer on slower systems. 

## Checkout HiFiBerryOS sources

```
git clone https://github.com/hifiberry/hifiberry-os
cd hifiberry-os
```

## Install necessary tools

```
./prepare-software
```

This will install some packages that are required to build HiFiBerryOS.

## Download and extract buildroot

```
./get-buildroot
```

Starting March 2020, we moved from the 2019-08 release of buildroot to the buildroot development tree.
This was necessary as the newest version (which is not yet officially released) includes some changes that
are required to move on with new features.
This script will download the correct release via git and apply a few necessary patches.

## Start the first build

Now, change to the HiFiBerryOS directory, create a configuration and compile HiFiBerryOS
```
cd hifiberry-os
./build-config 3
./compile 3
```

This will take some time. Depending on your hardware and network connectivity, expect at least one hour, but it can be also much longer.

## Parallel builds

Builds for a specific platform (e.g. Pi3 or Pi4) are store in separate directories. This means you can run a parallel builds for multiple platforms. Especially for systems with a lots of cores and fast SSDs, this is usually faster than running 
them sequentially. 
