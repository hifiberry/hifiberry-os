# Setting up the development environment

## Install necessary tools

```
sudo apt-get install -y git make gcc g++ unzip rsync bc sshpass zip ncurses-dev screen
```

## Download and extract buildroot

```
wget https://buildroot.org/downloads/buildroot-2019.08.1.tar.gz
tar xvzf buildroot-2019.08.1.tar.gz
ln -s buildroot-2019.08.1 buildroot
```
Note that newer releases than buildroot 2019-08 won't work at the moment due to incompatibilities
of the Python interpreter.

## Install Prerequisites
```
cd hifiberry-os
./prepare-software
```

## Clone the HiFiBerryOS sources

```
git clone https://github.com/hifiberry/hifiberry-os
```

## Patch buildroot

We require some changes in official buildroot packages (e.g. upgrades to newer versions). Before compiling, 
apply these changes using

```
cd hifiberry-os
./fix-buildroot
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

Builds for a specific platform (e.g. Pi3 or Pi4) are store in separate directories. This means you can run a parallel builds for multiple platforms. Especially for systems with a lots of cores and fast SSDs, this is usually faster than running 
them sequentially. 
