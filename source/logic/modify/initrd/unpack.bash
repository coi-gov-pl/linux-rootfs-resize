#!/usr/bin/env bash

include logger.bash

function initrd.unpack {
  logger.info ">> Unpacking Initramfs image to temporary folder"

  local initrd=$(facter.get initrd)
  local initrd_packaging=$(facter.get initrd_packaging)
  local lvm=$(facter.get lvm)
  logger.debug "Initramfs image: ${COLOR_CYAN}${initrd}"
  logger.debug "Initramfs image archive type: ${COLOR_CYAN}${initrd_packaging}"
  logger.debug "Does rootfs uses LVM: ${COLOR_CYAN}${lvm}"

  initrd.create-temp-dir

  if [[ $initrd_packaging == 'gzip' ]]; then
    initrd.unpack.gziped
  elif [[ $initrd_packaging == 'cpio' ]]; then
    initrd.unpack.cpio
  fi
}

function initrd.create-temp-dir {
  local tempdir=$(mktemp -dt initrd-unpacked.XXXXXX)
  facter.set initrd_tempdir "${tempdir}"
  trap initrd.remove-temp-dir EXIT
}

function initrd.remove-temp-dir {
  local tempdir=$(facter.get initrd_tempdir)
  logger.debug "Removing temp dir: ${tempdir}"
  rm -rf ${tempdir}
}

function initrd.unpack.gziped {
  local tempdir=$(facter.get initrd_tempdir)
  logger.info '>>> Unpacking gziped Initramfs'
  cd $tempdir
  executor.stream "gunzip -c ${initrd} | cpio -i --make-directories"
}

function initrd.unpack.cpio {
  local tempdir=$(facter.get initrd_tempdir)
  logger.info '>>> Unpacking CPIO Initramfs'

  cd $tempdir
  executor.stream "/usr/lib/dracut/skipcpio ${initrd} | gunzip -c | cpio -i"
}
