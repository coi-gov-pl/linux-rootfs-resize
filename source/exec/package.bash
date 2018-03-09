#!/usr/bin/env bash

include facter.bash
include exec/executor.bash

APT_UPDATE_INTERVAL=${APT_UPDATE_INTERVAL:-7200}

function package.apt.last-update {
  local apt_date="$(stat -c %Y '/var/cache/apt')"
  local now_date="$(date +'%s')"

  echo $((now_date - apt_date))
}

function package.apt.ensure-updated {
  if [[ "$(package.apt.last-update)" -gt $APT_UPDATE_INTERVAL ]]; then
    executor.stream 'apt-get update -m'
  fi
}

function package.install {
  local packages="$@"
  if [[ "$(facter.get 'osfamily')" == 'RedHat' ]]; then
    package.install.redhat "$packages"
  else
    package.install.debian "$packages"
  fi
}

function package.install.debian {
  local packages="$@"
  # TODO: check packages installed already
  executor.stream "apt-get install -y ${packages}"
}

function package.install.redhat {
  local packages="$@"
  # TODO: check packages installed already
  executor.stream "yum install -y ${packages}"
}
