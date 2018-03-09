#!/bin/bash

include logger.bash
include facter.bash
include validation/root.bash
include view/colors.bash

function install-prerequisites {
  logger.info '==> Installing prerequisites'

  local osfamily="$(facter.get 'osfamily')"
  local operatingsystem="$(facter.get 'operatingsystem')"
  local operatingsystemrelease="$(facter.get 'operatingsystemrelease')"

  logger.info "OS Family: ${COLOR_CYAN}${osfamily}"
  logger.info "OS: ${COLOR_CYAN}${operatingsystem}"
  logger.info "OS Release: ${COLOR_CYAN}${operatingsystemrelease}"
}
