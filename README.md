Linux Rootfs Resize
===================

Supported Linux distributions: CentOS 6, Debian 6, Debian 7.

Rework of my previous project, that was limited only to CentOS 6.

This tool creates new initrd (initramfs) image with ability to resize root filesystem over available space. Tipically you need this when you provision your virtual machine on OpenStack cloud for the first time (your image becomes flavor aware)

For now, filesystem resize is limited to ext2, ext3 and ext4 (resize2fs) including LVM volumes.

This code was successfuly tested on: CentOS 6.5, Debian 6 and Debian 7.2

DEPENDENCIES:

```bash
    cloud-utils (https://launchpad.net/cloud-utils)
    parted (CentOS)
```

INSTALL:

    Install git, clone this project on your machine, run 'install'.

On CentOS:

```bash
    cd /opt
    rpm -ivh http://ftp-stud.hs-esslingen.de/pub/epel/6/i386/epel-release-6-8.noarch.rpm
    yum install git parted cloud-utils
    git clone https://github.com/flegmatik/linux-rootfs-resize.git
    cd linux-rootfs-resize
    ./install
```

On Ubuntu 14.04 :

```bash
    apt-get update
    apt-get install -y git parted cloud-utils
    git clone https://github.com/ton-katsu/linux-rootfs-resize.git
    cd linux-rootfs-resize
    ./install
    cd ..
    rm -rf ./linux-rootfs-resize
```

Tool is designed in modular fashion, so support for other distributions can be added without much work (I hope).
