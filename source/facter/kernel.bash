#!/usr/bin/env bash

include facter/os.bash

function facter.kernel.calculate {
  local osfamily=$(facter.get 'osfamily')
  local initrd
  if [[ $osfamily == 'RedHat' ]]; then
    initrd="/boot/initramfs-$(uname -r).img"
  elif [[ $osfamily == 'Debian' ]]; then
    initrd="/boot/initrd.img-$(uname -r)"
  fi
  facter.set initrd "${initrd}"
  facter.set vmlinuz "/boot/vmlinuz-$(uname -r)"
  facter.set kernel_version "$(uname -r)"
}

facter.kernel.calculate
