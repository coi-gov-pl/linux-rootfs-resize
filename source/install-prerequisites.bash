#!/bin/bash

include logger.bash
include facter.bash
include validation/root.bash
include view/colors.bash
include exec/executor.bash
include exec/package.bash

function install-prerequisites {
  logger.info '==> Installing prerequisites'

  local osfamily="$(facter.get 'osfamily')"
  local operatingsystem="$(facter.get 'operatingsystem')"
  local operatingsystemrelease="$(facter.get 'operatingsystemrelease')"

  logger.info "OS Family: ${COLOR_CYAN}${osfamily}"
  logger.info "OS: ${COLOR_CYAN}${operatingsystem}"
  logger.info "OS Release: ${COLOR_CYAN}${operatingsystemrelease}"

  install-prerequisites.repositories

  package.install 'parted cloud-utils'
}

function install-prerequisites.repositories {
  if [[ "$(facter.get 'osfamily')" == 'RedHat' ]]; then
    install-prerequisites.epel
  fi
}

function install-prerequisites.epel {
  logger.info 'Installing EPEL'
  local uri="https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(facter.get 'operatingsystemmajrelease').noarch.rpm"
  if ! rpm -q 2>&1 >/dev/null; then
    if [[ "$(facter.get 'operatingsystem')" == 'CentOS' ]]; then
      executor.stream 'yum install -y epel-release'
    else
      executor.stream "yum install -y ${uri}"
    fi
  fi
}
