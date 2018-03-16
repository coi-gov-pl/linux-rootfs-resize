#!/usr/bin/env bash

include facter.bash
include facter/os.bash

function facter.resolve.kernel {
  local osfamily
  osfamily=$(facter.get 'osfamily')
  local operatingsystemmajrelease
  operatingsystemmajrelease=$(facter.get 'operatingsystemmajrelease')
  local initrd
  if [[ $osfamily == 'RedHat' ]]; then
    initrd="/boot/initramfs-$(uname -r).img"
  elif [[ $osfamily == 'Debian' ]]; then
    initrd="/boot/initrd.img-$(uname -r)"
  fi
  facter.set initrd "${initrd}"
  facter.set kernel "/boot/vmlinuz-$(uname -r)"
  facter.set kernel_version "$(uname -r)"
  facter.resolve.initrd-packaging
}

function facter.resolve.initrd-packaging {
  local initrd
  initrd=$(facter.get initrd)
  local initrd_packaging
  initrd_packaging=unknown
  local fdesc
  fdesc=$(file ${initrd})
  if echo "${fdesc}" | grep -q gzip; then
    initrd_packaging=gzip
  elif echo "${fdesc}" | grep -q cpio; then
    initrd_packaging=cpio
  else
    logger.error "Unknown packaging of Initramfs image: ${fdesc}"
    exit 6
  fi
  facter.set initrd_packaging ${initrd_packaging}
}

facter.resolve.kernel
