# Setting up the development environment

## Install necessary tools

```
sudo apt-get install -y git make gcc g++ unzip rsync bc sshpass zip ncurses
```

## Download and extract buildroot

```
wget https://buildroot.org/downloads/buildroot-2019.08.1.tar.gz
tar xvzf buildroot-2019.08.1.tar.gz
ln -s buildroot-2019.08.1 buildroot
```

## Clone the HiFiBerryOS sources

```
git clone https://github.com/hifiberry/hifiberry-os
```

## Start the first build

Now, change to the HiFiBerryOS directory, create a configuration and compile HiFiBerryOS
```
cd hifiberry-os
./build-config 3
./compile 3
```

This will take some time. Depending on your hardware and network connectivity, expect at least one hour, but it can be also much longer.

## Parallel builds

You might want to work on a Pi3 and Pi4 version at the same time. This would require a complete rebuild each time you 
switch to the other Pi version. To deal with this, you can use multiple buildroot directories.
Just duplicate buildroot to buildroot-0w, buildroot-2, buildroot-3, buildroot-4. Note that you have to *copy* the directories, as each build will store it's data and configuration in one of these.
If the buildroot-xxx directory does not exist, build process will use the buildroot directory, but no parallel build 
are possible in this case.
