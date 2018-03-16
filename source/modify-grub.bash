#!/bin/bash

include logger.bash
include facter.bash

function modify-grub {
  logger.info '==> Modifing GRUB'

  local grub_version osfamily osfamily_lcase

  grub_version=$(facter.get grub_version)
  osfamily=$(facter.get osfamily)
  osfamily_lcase=${osfamily,,}

  logger.info "Grub version: ${COLOR_CYAN}${grub_version}"

  if [[ $grub_version == '2' ]]; then
    modify-grub.modern.${osfamily_lcase}
  else
    modify-grub.legacy.${osfamily_lcase}
  fi
}

function modify-grub.modern.redhat {
  logger.info "Attaching growrooted Initramfs to GRUB2 for Red Hat family"
}


function modify-grub.modern.debian {
  logger.info "Attaching growrooted Initramfs to GRUB2 for Debian family"
}

function modify-grub.legacy.redhat {
  logger.info "Attaching growrooted Initramfs to GRUB Legacy for Red Hat family"
}

function modify-grub.legacy.debian {
  logger.info "Attaching growrooted Initramfs to GRUB Legacy for Debian family"
}
