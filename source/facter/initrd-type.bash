#!/usr/bin/env bash

function facter.resolve.initrd-type {
  local initrd_unpacked initrd_tempdir initrd_init_filetype initrd_init_type
  initrd_unpacked=$(facter.get initrd_unpacked)
  if ! [[ "${initrd_unpacked}-X" == "yes-X" ]]; then
    logger.error 'Tring to resolve initrd type before unpacking it'
    exit 125
  fi
  initrd_tempdir=$(facter.get initrd_tempdir)
  initrd_init_filetype="$(file $(readlink -f ${initrd_tempdir}/init))"
  logger.debug "Init file type: ${initrd_init_filetype}"
  if echo "${initrd_init_filetype}" | grep -q 'GNU/Linux'; then
    initrd_init_type='systemd'
  else
    if [ -f "${initrd_tempdir}/scripts/local" ]; then
      initrd_init_type='systemv-scripts-local'
    else
      initrd_init_type='systemv-plain-init'
    fi
  fi
  facter.set initrd_init_type ${initrd_init_type}
}
