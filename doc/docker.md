# Adding 3rd party software in Docker containers

## Preface

Starting with the January 2021 release, HiFiBerryOS comes with Docker that allows you to add 3rd party software. While Docker is a way to build light-weight containers, it will still add load to the system and the SD card.
Depending on the containers that you're using, write requests to the SD card can increase dramatically. This might reduce the lifespan of your SD card. 

## Hardware

We recommend a Pi4 and at least a 32GB SD card. It is best to use a large SD card. Also a Pi4 with more than 1GB RAM might make sense - depending on the software you plan to add.

## Preparations

If you are using an older installation that has just been upgraded, a fresh installation is recommended. The reason for this is that the older HiFiBerryOS releases use a relatively small root file system. That was fine as long as no 3rd party was added, but docker containers often add a huge amount of extra data that needs to be stored somewhere.

## Directory structure

All docker container configuration and data reside in /data/docker
For each application, there's a directory /data/docker/\<appname\>. You need to create this for your applications.
The most important file in this directory is a docker-compose.yaml file that defines the conatiner(s) for this application. It's a standard docker-compose configuration file.

If your docker container requires persistent data, store this in the same directory (or better create a subdirectory)

## Do's and dont's

- Remember that docker containers are stateless. Don't expect data in a container to persist. Always store data that needs to be persistant in /data/docker/\<appname\>
- Minimize writes to the SD card
- Add 0.0.0.0: to the exposed ports to avoid a bug that prevents the containers from starting.

## Example

The following example shows how to install Logitech Media Server (LMS) on the system:

### Prepare directory
```mkdir -p /data/docker/lms
mkdir -p /data/docker/lms/config
```
The config directory is uses later to access the LMS configuration.

### docker-compose.yaml

Put the following file into /data/docker/lms

```
version: '3'
services:
  lms:
    container_name: lms
    image: lmscommunity/logitechmediaserver
    volumes:
      - /data/docker/lms/config:/config:rw
      - /data/library/music:/music:ro
      - /data/library/playlists:/playlist:ro
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    ports:
      - 0.0.0.0:9000:9000/tcp
      - 0.0.0.0:9090:9090/tcp
      - 0.0.0.0:3483:3483/tcp
      - 0.0.0.0:3483:3483/udp
    restart: always
```

## Test

```cd /data/docker/lms
docker-compose up
```

Now test if everything is working as expected. 

## Start

You can now either reboot the system or just run the container start script:
```
/opt/hifiberry/bin/start-containers
```

## Check

If your container was set up correctly, it should be listed as running:
```
# docker container list
CONTAINER ID        IMAGE                              COMMAND             CREATED             STATUS              PORTS
                        NAMES
05301ad1f93c        lmscommunity/logitechmediaserver   "start-container"   2 minutes ago       Up 2 minutes        0.0.0.0:3483->3483/tcp, 0.0.0.0:9000->9000/tcp, 0.0.0.0:9090->9090/tcp, 0.0.0.0:3483->3483/udp   lms
```
