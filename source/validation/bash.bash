#!/bin/bash

include facter/bash.bash

function validate-bash-version {
  if (( $BASH_MAJOR_VERSION < 4 )); then
    echo "BASH version >= 4 is required, running on ${bash_version}" 1>&2
    exit 1
  fi
}

validate-bash-version
