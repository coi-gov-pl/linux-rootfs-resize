#!/usr/bin/env bash

include logger.bash

function view.welcome {
  logger.info 'Welcome to linux-rootfs-resize script!'
  logger.info '--------------------------------------'
  logger.info 'It will try to automatically resize root partition by changing'
  logger.info 'initramfs  linux  image and modifing  Grub. To actually resize'
  logger.info 'this partition, please reboot this machine!'
  logger.info ''
}
