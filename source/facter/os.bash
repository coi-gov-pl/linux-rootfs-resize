#!/usr/bin/env bash

include facter.bash
include logger.bash

function facter.os.resolve {
  if [ -f /etc/redhat-release ]; then
    facter.set 'osfamily' 'RedHat'
    facter.os.redhat.resolve
  elif [ -f /etc/debian_version ]; then
    facter.set 'osfamily' 'Debian'
    facter.os.debian.resolve
  else
    logger.error 'Unsupported OS Family. Supported families are: RedHat and Debian'
    exit 5
  fi
  local major=$(facter.get 'operatingsystemrelease' | cut -d '.' -f 1)
  facter.set 'operatingsystemmajrelease' $major
}

function facter.os.debian.resolve {
  if [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    facter.set 'operatingsystem' $DISTRIB_ID
    facter.set 'operatingsystemrelease' $DISTRIB_RELEASE
  else
    facter.set 'operatingsystem' 'Debian'
    facter.set 'operatingsystemrelease' $(cat /etc/debian_version)
  fi
}

function facter.os.redhat.resolve {
  # https://regex101.com/r/Uvm9bs/3
  local RHEL_SED_VERSION_PARSE='s/^[^0-9]+([0-9]+(\.[0-9]+)?).*$/\1/'
  local version
  if [ -f /etc/oracle-release ]; then
    facter.set 'operatingsystem' 'OracleLinux'
    version=$(cat /etc/oracle-release | sed -E $RHEL_SED_VERSION_PARSE)
  elif [ -f /etc/centos-release ]; then
    facter.set 'operatingsystem' 'CentOS'
    version=$(cat /etc/centos-release | sed -E $RHEL_SED_VERSION_PARSE)
  elif [ -f /etc/fedora-release ]; then
    facter.set 'operatingsystem' 'Fedora'
    version=$(cat /etc/fedora-release | sed -E $RHEL_SED_VERSION_PARSE)
  else
    facter.set 'operatingsystem' 'RedHat'
    version=$(cat /etc/redhat-release | sed -E $RHEL_SED_VERSION_PARSE)
  fi
  facter.set 'operatingsystemrelease' $version
}

facter.os.resolve
