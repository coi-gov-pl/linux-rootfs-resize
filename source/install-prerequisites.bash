#!/bin/bash

include logger.bash
include facter.bash
include validation/root.bash
include validation/os.bash
include view/colors.bash
include exec/executor.bash
include exec/package.bash

function install-prerequisites {
  logger.info '==> Installing prerequisites'

  local osfamily

  osfamily="$(facter.get 'osfamily')"
  local operatingsystem
  operatingsystem="$(facter.get 'operatingsystem')"
  local operatingsystemrelease
  operatingsystemrelease="$(facter.get 'operatingsystemrelease')"

  logger.info "OS Family: ${COLOR_CYAN}${osfamily}"
  logger.info "OS: ${COLOR_CYAN}${operatingsystem}"
  logger.info "OS Release: ${COLOR_CYAN}${operatingsystemrelease}"

  install-prerequisites.repositories

  local packages

  packages='parted cloud-utils cpio gzip sed'
  local initrd_packaging
  initrd_packaging=$(facter.get initrd_packaging)
  if [[ $initrd_packaging == 'cpio' ]]; then
    packages="$packages dracut"
  fi
  logger.debug "Prerequisites: ${packages}"
  package.install "${packages}"
}

function install-prerequisites.repositories {
  local osfamily
  osfamily=$(facter.get 'osfamily')
  local operatingsystem
  operatingsystem=$(facter.get 'operatingsystem')
  local operatingsystemmajrelease
  operatingsystemmajrelease=$(facter.get 'operatingsystemmajrelease')
  if [[ $osfamily == 'RedHat' ]]; then
    install-prerequisites.epel
  elif [[ $operatingsystem == 'Debian' ]] && [ $operatingsystemmajrelease -lt 8 ]; then
    package.apt.add-repo 'http://http.debian.net/debian' wheezy-backports main
  fi
}

function install-prerequisites.epel {
  logger.info 'Installing EPEL'
  local uri
  uri="https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(facter.get 'operatingsystemmajrelease').noarch.rpm"
  if [[ "$(facter.get 'operatingsystem')" == 'CentOS' ]]; then
    package.install epel-release
  else
    if ! package.is-installed epel-release; then
      executor.stream "yum install -y ${uri}"
    fi
  fi
}
