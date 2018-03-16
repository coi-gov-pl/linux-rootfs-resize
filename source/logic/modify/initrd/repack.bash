#!/usr/bin/env bash

include logger.bash
include facter.bash
include exec/executor.bash

function initrd.repack {
  logger.info ">> Repacking Initramfs image"

  local initrd_tempdir=$(facter.get initrd_tempdir)
  local cpio_tempfile=$(mktemp -t initrd-XXXXXX.cpio)
  local initrd_packaging=$(facter.get initrd_packaging)
  local initrd=$(facter.get initrd)
  local initrd_basename=$(basename $initrd)
  local initrd_dirname=$(dirname $initrd)
  local initrd_growroot="${initrd_dirname}/growroot-${initrd_basename}"

  facter.set initrd_growroot ${initrd_growroot}

  executor.stream "rm -rfv ${cpio_tempfile}"
  pushd $initrd_tempdir >/dev/null 2>&1
  executor.stream "find ./ | cpio -H newc -o > ${cpio_tempfile}"
  popd >/dev/null 2>&1

  if [[ $initrd_packaging == 'gzip' ]]; then
    initrd.repack.gzip "${initrd_growroot}" "${cpio_tempfile}"
  elif [[ $initrd_packaging == 'cpio' ]]; then
    initrd.repack.cpio "${initrd_growroot}" "${cpio_tempfile}"
  fi

  executor.stream "rm -rfv ${cpio_tempfile}"

  logger.info "Modified Initramfs image: ${COLOR_CYAN}${initrd_growroot}"
}

function initrd.repack.gzip {
  local initrd_growroot="$1"
  local cpio_tempfile="$2"

  executor.stream "gzip -c ${cpio_tempfile} > ${initrd_growroot}"
}

function initrd.repack.cpio {
  local initrd_growroot="$1"
  local cpio_tempfile="$2"

  executor.stream "cp -v ${cpio_tempfile} ${initrd_growroot}"
}
