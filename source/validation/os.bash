#!/usr/bin/env bash

include logger.bash
include facter.bash

function validate-os {
  local osfamily=$(facter.get 'osfamily')
  local operatingsystem=$(facter.get 'operatingsystem')
  local operatingsystemmajrelease=$(facter.get 'operatingsystemmajrelease')

  if [[ $osfamily == 'RedHat' ]] && [ $operatingsystemmajrelease -lt 6 ]; then
    logger.error "Unsupported OS - ${operatingsystem} ${operatingsystemmajrelease}. Red Hat family is supported from version 6."
    exit 5
  elif [[ $operatingsystem == 'Debian' ]] && [ $operatingsystemmajrelease -lt 7 ]; then
    logger.error "Unsupported OS - ${operatingsystem} ${operatingsystemmajrelease}. Debian OS is supported from version 7."
    exit 5
  elif [[ $operatingsystem == 'Ubuntu' ]] && [ $operatingsystemmajrelease -lt 14 ]; then
    logger.error "Unsupported OS - ${operatingsystem} ${operatingsystemmajrelease}. Ubuntu OS is supported from version 14.04."
    exit 5
  fi
}
validate-os
