#!/usr/bin/env bash

include logger.bash
include facter.bash

function initrd.modify-init {
  logger.info ">> Modifing init stript in Initramfs image"

  local initrd_init_type=$(facter.get initrd_init_type)
  logger.debug "Initramfs init type: ${COLOR_CYAN}${initrd_init_type}"

  
}
