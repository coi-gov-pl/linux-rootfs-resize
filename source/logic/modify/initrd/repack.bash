#!/usr/bin/env bash

include logger.bash
include facter.bash
include exec/executor.bash

function initrd.repack {
  logger.info ">> Repacking Initramfs image"

  local initrd_tempdir cpio_tempfile initrd_packaging initrd initrd_growroot

  initrd_tempdir=$(facter.get initrd_tempdir)
  cpio_tempfile=$(mktemp -t initrd-XXXXXX.cpio)
  initrd_packaging=$(facter.get initrd_packaging)
  initrd=$(facter.get initrd)
  initrd_growroot=$(echo $initrd | sed -E 's/(\.img)?$/-growroot\1/')

  facter.set initrd_growroot ${initrd_growroot}

  executor.silently "rm -rfv ${cpio_tempfile}"
  pushd $initrd_tempdir >/dev/null 2>&1
  executor.silently "find ./ | cpio -H newc -o > ${cpio_tempfile}"
  popd >/dev/null 2>&1

  if [[ $initrd_packaging == 'gzip' ]]; then
    initrd.repack.gzip "${initrd_growroot}" "${cpio_tempfile}"
  elif [[ $initrd_packaging == 'cpio' ]]; then
    initrd.repack.cpio "${initrd_growroot}" "${cpio_tempfile}"
  fi

  executor.silently "rm -rfv ${cpio_tempfile}"

  logger.info "Modified Initramfs image: ${COLOR_CYAN}${initrd_growroot}"
}

function initrd.repack.gzip {
  local initrd_growroot cpio_tempfile

  initrd_growroot="$1"
  cpio_tempfile="$2"

  executor.silently "gzip -c ${cpio_tempfile} > ${initrd_growroot}"
}

function initrd.repack.cpio {
  local initrd_growroot cpio_tempfile

  initrd_growroot="$1"
  cpio_tempfile="$2"

  executor.silently "cp -v ${cpio_tempfile} ${initrd_growroot}"
}
