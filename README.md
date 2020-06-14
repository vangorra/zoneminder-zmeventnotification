# zoneminder-zmeventnotification [![Build status](https://github.com/vangorra/zoneminder-zmeventnotification/workflows/Build/badge.svg?branch=master)](https://github.com/vangorra/zoneminder-zmeventnotification/actions?workflow=Build)
A docker container prebuilt for zoneminder and zmeventnotification that supports CPU processing. This is built on top of the official zoneminder docker image.

## Features

- Built from official zoneminder docker image.
- Custom OpenCV build.
- Full install of zmeventnotification.
- Full install of mlapi (for faster image detection).

## Usage (CPU Image Processing) 
```yaml
version: '2.3'
services:
  zoneminder:
    image: 'vangorra/zoneminder-zmeventnotification:cpu'
    ports:
      - '1080:1080' # Zone minder port.
      - '9000:9000' # Event notification port.
    devices:
        - /dev/dri
    volumes:
      - '/etc/localtime:/etc/localtime:ro'
      - './container_data/zoneminder/events:/var/cache/zoneminder/events'
      - './container_data/zoneminder/images:/var/cache/zoneminder/images'
      - './container_data/zoneminder/mysql:/var/lib/mysql'
      - './container_data/zoneminder/logs:/var/log/zm'
      - './container_data/zoneminder/zmeventnotification/config/mlapiconfig.ini:/etc/zm/mlapiconfig.ini:ro'      - './container_data/zoneminder/zmeventnotification/config/zmeventnotification.ini:/etc/zm/zmeventnotification.ini:ro'
      - './container_data/zoneminder/zmeventnotification/config/objectconfig.ini:/etc/zm/objectconfig.ini:ro'
      - './container_data/zoneminder/zmeventnotification/config/secrets.ini:/etc/zm/secrets.ini:ro'
    shm_size: "8632M" # Needed for monitoring cameras. This value will vary depending on your setup and cameras.
    environment:
      TZ: 'America/Los_Angeles'
    restart: unless-stopped
```

## Event Notification Configs
Configuration for this zmeventnotification is well documented here: https://zmeventnotification.readthedocs.io/ and https://github.com/pliablepixels/zmeventnotification.

Config files can be located here:
- https://github.com/pliablepixels/zmeventnotification/blob/master/zmeventnotification.ini
- https://github.com/pliablepixels/zmeventnotification/blob/master/hook/objectconfig.ini
