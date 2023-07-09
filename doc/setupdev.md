# Setting up the development environment

*Note:* The scripts are designed to work on Ubuntu. There is a good chance that they will also work on other Debian-based
systems. For other Linux distributions, you might have to adapt some of these scripts.

## Compilation environment

The system you're using should have at least 16GB RAM (more is better). With the latest addition of Webkit, running on a CPU with many cores/threads (eg. 16/32), 16GB might not be enough memory anymore. You should have at least 1GB RAM per thread (e.g. for e Ryzen 3950X that means 32GB).
Using a VM for the compilation works well, but we recommend at least 150GB disk space for it (might not be enough for multiple parallel  builds). An SSD is highly recommended.

We can't recommend the Windows Subsystem for Linux due to it's poor I/O performance. As the build creates, reads and writes a huge amount of files, the build on WSL will be very slow.

Our build system uses an Ryzen 3950X with 64GB RAM (max. 50MB to the build VM) and 300GB SSD disk space. This allows to run multiple build (e.g. Pi 2,3,4) in parallel.

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

Builds for a specific platform (e.g. Pi3 or Pi4) are store in separate directories. This means you can run a parallel builds for multiple platforms. Especially for systems with a lots of cores and fast SSDs, this is usually faster than running them sequentially.

# Using the .devcontainer (experimental)

The HiFiBerryOS repository comes with a definition of a [VS Code Dev Container](https://code.visualstudio.com/docs/devcontainers/containers) - so if you have Docker set up and are using VS Code you can just start this repository in your container.
If you are using Windows as host system please clone the repository using the correct line ending setting, e.g.:
```bash
git clone git@github.com:hifiberry/hifiberry-os.git --config core.autocrlf=input
```
Especially if your `--system`-wide or `--global` git config uses `core.autocrlf=true`.

The container build will automatically
* install the necessary tools as seen in [Install necessary tools](#install-necessary-tools)
* make sure the working folders (i.e., `/workspaces/`) is owned by the `vscode` user of the container
* keep anything in ``/workspaces/`` in a Docker volume for faster consecutive builds (beware, this also mounts the git repo into that volume of which possible interference is untested)
* fix symlinks that break when cloning on Windows
* run the [`get-buildroot` command](#download-and-extract-buildroot)

for you (see [prepare script](../.devcontainer/prepare-devcontainer)).
The only thing left to do is follow the instruction of [Start the first build](#start-the-first-build)

:warning: **Build experience inside the Dev Container might be much poorer than bare metal.**

## Troubleshooting
* If you cloned the HiFiBerryOs repository under Windows and you encounter an issue in the devcontainer with the symlinks of `buildroot/package/spotifyd/spotifyd.mk` and `./buildroot/board/` setting up the devcontainer seems to have gone wrong as those should have been recreated during container build. In any case there is a script to fix those:

        ./.devcontainer/prepare-devcontainer --fix-symlinks

    This most likely results from cloning without the correct line endings (LF) set. Make sure you cloned the repository specifying `--config core.autocrlf=input`
* Beware of [this build issue](https://github.com/hifiberry/hifiberry-os/issues/142) resulting in the error `"Advanced Micro Devices X86-64", should be "ARM"`.
* In case anything stops working try rebuilding the VS Code Dev Container. Beware: there is a chance this might remove any already available build results living in a different docker volume (experimental).
