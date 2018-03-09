#!/bin/bash

function validate-bash-version {
  #statements
  local bash_version=$(LANG=C bash --version | grep 'GNU bash' | awk '{print $4}')
  local bash_maj_version=$(echo ${bash_version} | cut -d '.' -f 1)

  if (( $bash_maj_version < 4 )); then
    echo "BASH version >= 4 is required, running on ${bash_version}" 1>&2
    exit 1
  fi
}
validate-bash-version
