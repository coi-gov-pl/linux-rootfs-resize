#!/bin/bash

include logger.bash
include facter.bash

function modify-grub {
  logger.info '==> Modifing GRUB'

  local grub_version=$(facter.get grub_version)

  logger.info "Grub version: ${COLOR_CYAN}${grub_version}"
}
