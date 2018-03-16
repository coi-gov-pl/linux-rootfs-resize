#!/usr/bin/env bash

include logger.bash

LRR_CLEANUP=${LRR_CLEANUP:-yes}

function initrd.unpack {
  logger.info ">> Unpacking Initramfs image to temporary folder"

  local initrd=$(facter.get initrd)
  local initrd_packaging=$(facter.get initrd_packaging)
  logger.debug "Initramfs image: ${COLOR_CYAN}${initrd}"
  logger.debug "Initramfs image archive type: ${COLOR_CYAN}${initrd_packaging}"

  initrd.create-temp-dir

  if [[ $initrd_packaging == 'gzip' ]]; then
    initrd.unpack.gziped
  elif [[ $initrd_packaging == 'cpio' ]]; then
    initrd.unpack.cpio
  fi
  facter.set initrd_unpacked yes
  facter.resolve.initrd-type
}

function initrd.create-temp-dir {
  local tempdir
  if [[ $LRR_CLEANUP == 'yes' ]]; then
    tempdir=$(mktemp -dt initrd-unpacked.XXXXXX)
    trap initrd.remove-temp-dir EXIT
  else
    tempdir='/tmp/lrr-image'
    mkdir -p ${tempdir}
  fi
  facter.set initrd_tempdir "${tempdir}"
}

function initrd.remove-temp-dir {
  local tempdir=$(facter.get initrd_tempdir)
  logger.debug "Removing temp dir: ${tempdir}"
  rm -rf ${tempdir}
  facter.set initrd_unpacked no
}

function initrd.unpack.gziped {
  local tempdir=$(facter.get initrd_tempdir)
  logger.info '>>> Unpacking gziped Initramfs'
  local loc=$(pwd)
  cd $tempdir
  executor.silently "gunzip -c ${initrd} | cpio -i --make-directories"
  cd $loc
}

function initrd.unpack.cpio {
  local tempdir=$(facter.get initrd_tempdir)
  logger.info '>>> Unpacking CPIO Initramfs'

  local loc=$(pwd)
  cd $tempdir
  executor.silently "/usr/lib/dracut/skipcpio ${initrd} | gunzip -c | cpio -i"
  cd $loc
}
