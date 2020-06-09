# zoneminder-zmeventnotification [![Build status](https://github.com/vangorra/zoneminder-zmeventnotification/workflows/Build/badge.svg?branch=master)](https://github.com/vangorra/zoneminder-zmeventnotification/actions?workflow=Build)
A docker container prebuilt for zoneminder and zmeventnotification that supports CPU or GPU image processing. This is built on top of the official zoneminder docker image.

## Features

- Built from official zoneminder docker image.
- Custom OpenCV build.
- Full install of zmeventnotification.
- Full install of mlapi (for faster image detection).
- CPU and Nvidia GPU support. [Full tag list here](https://hub.docker.com/repository/docker/vangorra/zoneminder-zmeventnotification/tags).
  - Is your CUDA version not listed in the docker tags? File and issue requesting the version or submit a PR that adjusts the matrix of `.github/workflows/build.yml`.

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

## Usage (GPU Image Processing)
- Install the latest nvidia driver for your host OS.
```
# Install drivers detector.
$ sudo apt install ubuntu-drivers-common

# Determine the needed drivers.
$ ubuntu-drivers devices
  == /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
  modalias : pci:v000010DEd00000FFAsv0000103Csd0000094Bbc03sc00i00
  vendor   : NVIDIA Corporation
  model    : GK107GL [Quadro K600]
  driver   : nvidia-driver-435 - distro non-free
  driver   : nvidia-340 - distro non-free
  driver   : nvidia-driver-440 - distro non-free recommended
  driver   : nvidia-driver-390 - distro non-free
  driver   : xserver-xorg-video-nouveau - distro free builtin

# Install the drivers.
$ sudo apt install nvidia-driver-435 nvidia-utils-440

# Reboot the OS.
$ sudo reboot

# Determine the card model.
$ nvidia-smi 
Mon Jun  1 23:05:08 2020       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 440.59       Driver Version: 440.59       CUDA Version: 10.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Quadro K600         Off  | 00000000:01:00.0 Off |                  N/A |
| 26%   53C    P0    N/A /  N/A |      0MiB /   980MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

- Lookup the CUDA version on nvidia's website.
The model from the previous step is `Quadro K600`. Find the CUDA version for your model on the following website.
https://developer.nvidia.com/cuda-gpus

- Use the tag for your docker container.
The previous step reports the CUDA version for the `Quadro K600` is `3.0`. So the image we will use is `vangorra/zoneminder-zmeventnotification:gpu-cuda-3.0`.
Adjust your image accordingly.

Example:
```yaml
version: '2.3'
services:
  zoneminder:
    image: 'vangorra/zoneminder-zmeventnotification:gpu-cuda-3.0'
    ports:
      - '1080:1080' # Zone minder port.
      - '9000:9000' # Event notification port.
    devices:
        - /dev/dri
        - /dev/nvidia0
        - /dev/nvidiactl
        - /dev/nvidia-uvm
        - /dev/nvidia-uvm-tools
    volumes:
      - '/etc/localtime:/etc/localtime:ro'
      - './container_data/zoneminder/events:/var/cache/zoneminder/events'
      - './container_data/zoneminder/images:/var/cache/zoneminder/images'
      - './container_data/zoneminder/mysql:/var/lib/mysql'
      - './container_data/zoneminder/logs:/var/log/zm'
      - './container_data/zoneminder/zmeventnotification/config/zmeventnotification.ini:/etc/zm/zmeventnotification.ini:ro'
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
