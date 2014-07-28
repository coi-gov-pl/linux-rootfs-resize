linux-rootfs-resize
===================

Supported Linux distributions: CentOS 6, Debian 6, Debian 7 and Ubuntu.

Rework of my previous project, that was limited only to CentOS 6.

This tool creates new initrd (initramfs) image with ability to resize root filesystem 
over available space. Tipically you need this when you provision your virtual machine on 
OpenStack cloud for the first time (your image becomes flavor aware)

For now, filesystem resize is limited to ext2, ext3 and ext4 (resize2fs) including LVM volumes.

This code was successfuly tested on: CentOS 6.5, Debian 6, Debian 7.2, Ubuntu14.04

DEPENDENCIES:

    cloud-utils (https://launchpad.net/cloud-utils)
    parted (CentOS)

INSTALL: 

    Install git, clone this project on your machine, run 'install'. 

Curl Install:

    tar czvf /tmp/linux-rootfs-resize.tar.gz linux-rootfs-resize
    Edit curl-install.sh
        url="http://xxx.com/linux-rootfs-resize.tar.gz"
    Upload linux-rootfs-resize.tar.gz and curl-install.sh to xxx.com http-server.

    curl -s http://xxx.com/curl-install.sh | sudo bash


Tool is designed in modular fashion, so support for other distributions can be added without much work (I hope).


