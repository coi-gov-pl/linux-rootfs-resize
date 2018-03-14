#!/usr/bin/env bash

include facter.bash
include exec/executor.bash

APT_UPDATE_INTERVAL=${APT_UPDATE_INTERVAL:-7200}

# public functions

function package.install {
  local packages="$@"
  if [[ "$(facter.get 'osfamily')" == 'RedHat' ]]; then
    package.install.redhat "$packages"
  else
    package.install.debian "$packages"
  fi
}

function package.apt.clear-cache {
  mkdir -p /var/cache/apt
  touch -d "365 days ago" /var/cache/apt
}

function package.apt.add-repo {
  local address="$1"
  local reponame="$2"
  local scope="$3"
  local comment="${4:-${reponame}}"
  local line="deb ${address} ${reponame} ${scope}"
  local line_w_comment="${line} # ${comment}"
  if ! grep -qE "^${line}" /etc/apt/sources.list; then
    logger.debug "Adding repo: ${line}"
    echo "${line_w_comment}" >> /etc/apt/sources.list
    package.apt.clear-cache
  fi
}

# private functions - do not use

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

function package.install.debian {
  local packages="$@"
  local tobeinstalled="$(package.filter-installed $packages)"
  if [[ "${tobeinstalled}-X" != '-X' ]]; then
    package.apt.ensure-updated
    executor.stream "apt-get install -y ${tobeinstalled}"
  fi
}

function package.install.redhat {
  local packages="$@"
  local tobeinstalled=`package.filter-installed $packages`
  if [[ "${tobeinstalled}-X" != '-X' ]]; then
    executor.stream "yum install -y ${tobeinstalled}"
  fi
}

function package.filter-installed {
  local packages="$@"
  local tobeinstalled=''
  for package in $(echo $packages); do
    if ! package.is-installed $package; then
      tobeinstalled="$tobeinstalled $package"
      tobeinstalled=$(echo $tobeinstalled)
    fi
  done
  echo $tobeinstalled
}

function package.is-installed {
  local packagename="$1"
  local installed="$(package.info "${packagename}" | cut -d: -f1)"
  if [[ $installed == 'yes' ]]; then
    return 0
  else
    return 1
  fi
}

function package.version {
  local packagename="$1"
  echo "$(package.info "${packagename}" | cut -d: -f2)"
}

function package.info {
  local packagename="$1"
  if [[ "$(facter.get 'osfamily')" == 'RedHat' ]]; then
    local command="rpm -q --nosignature --nodigest --qf '%{VERSION}-%{RELEASE}.%{ARCH}' ${packagename}"
    local version
    version=`${command}`
    if [ $? -eq 0 ]; then
      local installed='yes'
    else
      local installed='no'
    fi
  else
    local command="dpkg-query -W --showformat \${Status}\:\${Version} ${packagename}"
    local info
    info=`${command} 2>/dev/null`
    local version="$(echo ${info} | cut -d: -f2)"
    local installed="$(echo ${info} | cut -d: -f1)"
    if [[ "${installed}" == 'install ok installed' ]]; then
      installed='yes'
    else
      installed='no'
    fi
  fi
  logger.debug "Package ${packagename} - installed: ${installed}, version: ${version}"
  echo "${installed}:${version}"
}
